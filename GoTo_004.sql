
--SUB-ROUTINE DEFINITIONS:
BEGIN
	goto start /* to prevent early evaluation of below */

	/* variables referenced in multiple subroutines: */
	declare @x		bigint,
			@y		bigint,
			@L		tinyint,
			@LTemp	tinyint,
			@temp	bigint
	
	router: /* sub-module to transfer control based on @L (label) value: */
	begin
		if @L=3 goto L3
		else if @L=4 goto L4
		else if @L=5 goto L5
		else if @L=6 goto L6		
		else if @L=9 goto L9
		else if @L=10 goto L10
		else if @L=11 goto L11
		else if @L=12 goto L12
		else return
	end	

	Factorial:
	begin 
		declare @Factorial bigint;
		
		if(@x<1)
		 goto router;
		 
		declare @fact_i int = (@x-1);
		set @Factorial=@x;		
		
		Factorial_sub:
		begin
		 if(@fact_i<=1) 
		  goto router;
		 else 
		 begin
		  set @Factorial=(@Factorial*@fact_i);
		  set @fact_i=(@fact_i-1);
		  goto Factorial_sub;	
		 end
	    end		
	end

	fibo:
	begin
		declare @fibo bigint;

		declare @fibo_i	 int = 0,				
				@fibo1 int,
				@fibo2 int
	
		if(@x=0)
		begin
			set @fibo=0;
			goto router;
		end
		
		if(@x=1)
		begin
			set @fibo=1;
			goto router;
		end

		fibo_sub:
		begin
			if(@fibo_i>@x)
			begin				
				goto router;
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
	
	SumC1:
	begin
	 declare @SumC1 bigint;
	 if (@SumC1 is null)
	  set @SumC1=(select sum(C1) from #T0);
		  
	 goto router;
	end
		
	Seq:
	begin
	 declare @Seq int; 
	 set @Seq=(isnull(@Seq,0)+1);
	 goto router;
	end
		
	Foo:
	begin		
	 declare @Foo bigint=(@x*@y);
	 goto router;
	end
	
	Squared:
	begin
		declare @Squared bigint=(@x*@x);
		goto router;
	end

	Cubed:
	begin
		declare @Cubed bigint=(@x*@x*@x);
		goto router;
	end

	GTGT: /* example of sub-subroutine calls: */
	begin		
	 declare @gtgt bigint
	
	 /* save current @L: */
	 set @LTemp=@L;		
	 
	 /* call Squared(@x); output to @Squared: */
	 set @L=10; goto Squared; L10: 
	 	
	 /* call Cubed(@x); output to @Cubed: */	
	 set @L=11; goto Cubed; L11: 
	 
	 set @gtgt=(@Squared+@Cubed);
	 
	 /* reset @L: */
	 set @L=@LTemp;		
	 	 
	 goto router;		
	end		
END



start:
set nocount on;
declare	@c1	bigint,	@c2	bigint, @c3	bigint

--detail data:
drop table if exists #T0; create table #T0(C1 int,C2 int); insert into #T0(C1,C2) values(1,2),(2,3),(3,4),(5,6),(7,8);
	
--result data:
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

--loop through detail, calling sub-routines:
declare CSR1 cursor local fast_forward for select C1,C2 from #T0;
open CSR1; fetch next from CSR1 into @c1,@c2;
while @@FETCH_STATUS = 0
begin
	/* call SumC1(@x) where @x=@c1; output to @SumC1: */
	set @x=@c1; set @L=5; goto SumC1; L5: 
	
	/* call FiboC2(@x) where @x=@c2; output to @Fibo: */
	set @x=@c2;	set @L=4; goto Fibo; L4: 
		
	/* call Factorial(@x) where @x=(@c1+@c2); output to @Factorial: */
	set @x=(@c1+@c2); set @L=3; goto Factorial; L3: 

	/* call Seq() to increment @Seq: */
	set @L=6; goto Seq; L6: 

	/* call (Foo(@x,@y) where @x=@c1, @y=@c2; output to @Foo*/
	set @x=@c1; set @y=@c2; set @L=9; goto Foo; L9:

	/* call GTGT(@x) where @x=(@c1+@c2); output to @Gtgt: */
	set @x=(@c1+@c2); set @L=12; goto GTGT; L12:

	insert into #T1(C1,C2,SumC1,FiboC2,Fact,Seq,foo,GTGT)
		values(@c1,@c2,@SumC1,@Fibo,@Factorial,@Seq,@Foo,@Gtgt)

	fetch next from CSR1 into @c1,@c2;		
end close CSR1; deallocate CSR1;
select * from #T1;





