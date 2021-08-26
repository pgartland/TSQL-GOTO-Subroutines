/*
The following is an implementation of sub-routines in a TSQL script using GOTO in a controlled manner.

These sub-routines are equivalent to scalar functions with the following differences which are arguably adventageous:
(1) Parameters are in the same scope as the calling code; therefore they are passed by reference to the sub-routine. Note that this includes tables.
(2) Stateful behavior: variable declarations with assignments are re-run in subsequent calls; those without assignments are not.
(3) Memoization (per above): re-calculations of known values is avoided (see SumC1).

Like functions, these sub-routines may be referenced by name using a concise syntax.
For example, "select @Cubed=dbo.Cubed(@x);" is equivalent to "set @x=4 set @L=1; goto Cubed; L1:", after which @Cubed will contain the returned value and control will be set to the end of the statement.
One may think of "goto" in this context as equivalent to "exec", but in the same scope.

The contolled usage of GOTO is accomplished via the "Router" sub-routine which is a series of if/goto statements per the label number (@L) value.
Each sub-routine definition terminates with a call (goto) Router which returns control to the location immediately following the sub-routine call (see above).
If a label number is not found by Router, the script terminates via a return statement.
A sub-routine may call other sub-routines (see GTGT below. Additional "@LTemp# variables would be required to scale greater than 2 levels)
Sub-routines - which are bound by a label - may contain labels (see Factorial, Fibo) which may be used with traditional goto calls (that is, not using the above syntax) to implement iteration or recursion-like behavior.

Finally, this approach offers modularity similar to functions while not requiring deployment of any database objects.

*/
--SUB-ROUTINE DEFINITIONS:
BEGIN
	/* to prevent early evaluation of below */
	goto start 

	/* variables referenced in multiple subroutines: */
	declare @x		bigint,
			@y		bigint,
			@L		tinyint,
			@LTemp	tinyint,
			@temp	bigint
	
	/*Router(@L tinyint): sub-routine to transfer control per @L (label #) value: */
	Router: 
	begin
		if @L=1 goto L1
		if @L=2 goto L2
		if @L=3 goto L3
		if @L=4 goto L4		
		if @L=5 goto L5
		if @L=6 goto L6
		if @L=7 goto L7
		if @L=8 goto L8		
		return
	end	

	/* Factorial(@x bigint) : returns @Factorial bigint */
	Factorial:
	begin 		
		declare @Factorial bigint;
		
		if(@x<1)
		 goto Router;
		 
		declare @fact_i int = (@x-1);
		set @Factorial=@x;		
		
		Factorial_sub:
		begin
		 if(@fact_i<=1) 
		  goto Router;
		 else 
		 begin
		  set @Factorial=(@Factorial*@fact_i);
		  set @fact_i=(@fact_i-1);
		  goto Factorial_sub;	
		 end
	    end		
	end

	/* Fibo(@x bigint): returns @Fibo bigint */
	Fibo:
	begin
		declare @fibo bigint;

		declare @fibo_i	 int = 0,				
				@fibo1 int,
				@fibo2 int
	
		if(@x=0)
		begin
			set @fibo=0;
			goto Router;
		end
		
		if(@x=1)
		begin
			set @fibo=1;
			goto Router;
		end

		fibo_sub:
		begin
			if(@fibo_i>@x)
			begin				
				goto Router;
			end

			if(@fibo_i=0)
			begin
				set @fibo1=0;
				set @fibo2=0;
			end
			else if(@fibo_i=1)
			begin
				set @fibo1=0;
				set @fibo2=1;
			end
			else
			begin
				set @fibo=@fibo1+@fibo2;			
				set @fibo1=@fibo2;
				set @fibo2=@fibo;
			end
			
			set @fibo_i=(@fibo_i+1);			
			goto fibo_sub;
		end
	end	
	
	/* SumC1(C1 bigint): returns @SumC1 bigint 
	   Refers to specific temp table and column	*/
	SumC1:
	begin
	 declare @SumC1 bigint;
	 
	 /* memoization: */
	 if (@SumC1 is null)
	  set @SumC1=(select sum(C1) from #T0);
		  
	 goto Router;
	end
	
	/* Seq(@Seq int): returns @Seq int */
	Seq:
	begin
	 declare @Seq int; 
	 set @Seq=(isnull(@Seq,0)+1);
	 goto Router;
	end
		
	/* Foo(@x bigint, @y bigint): returns @Foo */
	Foo:
	begin		
	 declare @Foo bigint=(@x*@y);
	 goto Router;
	end
	
	/* Squared(@x bigint): returns @Squared */
	Squared:
	begin
		declare @Squared bigint=(@x*@x);
		goto Router;
	end

	/* Cubed(@x bigint): returns @Cubed bigint */
	Cubed:
	begin
		declare @Cubed bigint=(@x*@x*@x);
		goto Router;
	end

	/* GTGT(@x bigint): returns @Gtgt bigint  
	   Includes sub-subroutine calls    */
	GTGT: 
	begin		
	 declare @gtgt bigint
	
	 /* save current @L: */
	 set @LTemp=@L;		
	 
	 /* call Squared(@x); output to @Squared: */
	 set @L=7; goto Squared; L7: 
	 	
	 /* call Cubed(@x); output to @Cubed: */	
	 set @L=8; goto Cubed; L8: 
	 
	 set @gtgt=(@Squared+@Cubed);
	 
	 /* reset @L: */
	 set @L=@LTemp;		
	 	 
	 goto Router;		
	end		
END


/* script */
start:
set nocount on;
declare	@c1	bigint,	@c2	bigint, @c3	bigint

/* example detail data table: */
drop table if exists #T0; create table #T0(C1 int,C2 int); insert into #T0(C1,C2) values(1,2),(2,3),(3,4),(5,6),(7,8);
	
/* result data table: */
drop table if exists #T1; create table #T1
(
 C1		bigint,
 C2		bigint,
 SumC1	bigint,
 FiboC2	bigint,
 Fact	bigint,
 Seq	bigint,
 Foo	bigint,
 GTGT	bigint
);

/* loop through detail, calling sub-routines: */
declare CSR1 cursor local fast_forward for select C1,C2 from #T0;
open CSR1; fetch next from CSR1 into @c1,@c2;
while @@FETCH_STATUS = 0 
begin
	/* call SumC1(@x) where @x=@c1; output to @SumC1: */
	set @x=@c1 set @L=1 goto SumC1 L1: 
	
	/* call FiboC2(@x) where @x=@c2; output to @Fibo: */
	set @x=@c2 set @L=2 goto Fibo L2: 
		
	/* call Factorial(@x) where @x=(@c1+@c2); output to @Factorial: */
	set @x=(@c1+@c2) set @L=3 goto Factorial L3: 

	/* call Seq() to increment @Seq: */
	set @L=4 goto Seq L4: 

	/* call (Foo(@x,@y) where @x=@c1, @y=@c2; output to @Foo*/
	set @x=@c1 set @y=@c2 set @L=5 goto Foo L5:

	/* call GTGT(@x) where @x=(@c1+@c2); output to @Gtgt: */
	set @x=(@c1+@c2) set @L=6 goto GTGT L6:

	insert into #T1(C1,C2,SumC1,FiboC2,Fact,Seq,foo,GTGT)
		values(@c1,@c2,@SumC1,@Fibo,@Factorial,@Seq,@Foo,@Gtgt)

	fetch next from CSR1 into @c1,@c2;		
end close CSR1; deallocate CSR1;

/* review results */
select * from #T1;





