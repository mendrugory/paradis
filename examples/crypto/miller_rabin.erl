-module(miller_rabin).
-compile(export_all).
-export([rsa_tests/0, test/0, test1/0, test2/0,test3/0,test4/0,
	 is_probably_prime/1, make_prime/1]).

%% RSA-576 (174 digits)
%%   Note log(10)/log(2) = 3.3219
%%   576/3.3219 = 173.3932 => 174 decimal digits
%%   each prime has 174/2 => 87 digits
%%   To make N = 576 (we need 288 bits)
%%   miller_rabin:make_prime(288).

%% RSA-100 means 100 decimal digits
%% RSA-200 means 200 decimal digits and is the highest ever factored
%% RSA-576 means 576 binary digits (approx RSA-174 has not been factored)

rsa_test_cases() ->
    [{576, 188198812920607963838697239461650439807163563379417382700763356422988859715234665485319060606504743045317388011303396716199692321205734031879550656996221305168759307650257059},
     {640,3107418240490043721350750035888567930037346022842727545720161948823206440518081504556346829671723286782437916272838033415471073108501919548529007337724822783525742386454014691736602477652346609},
     {704, no, 74037563479561712828046796097429573142593188889231289084936232638972765034028266276891996419625117843995894330502127585370118968098286733173273108930900552505116877063299072396380786710086096962537934650563796359},
     {768,no, 1230186684530117755130494958384962720772853569595334792197322452151726400507263657518745202199786469389956474942774063845925192557326303453731548268507917026122142913461670429214311602221240479274737794080665351419597459856902143413},
     {896,no, 412023436986659543855531365332575948179811699844327982845455626433876445565248426198098870423161841879261420247188869492560931776375033421130982397485150944909106910269861031862704114880866970564902903653658867433731720813104105190864254793282601391257624033946373269391},
     {1024,no, 135066410865995223349603216278805969938881475605667027524485143851526510604859533833940287150571909441798207282164471551373680419703964191743046496589274256239341020864383202110372958725762358509643110564073501508187510676594629205563685529475213500852879416377328533906109750544334999811150056977236890927563},
     {1583,no,1847699703211741474306835620200164403018549338663410171471785774910651696711161249859337684305435744585616061544571794052229717732524660960646946071249623720442022269756756687378427562389508764678440933285157496578843415088475528298186726451339863364931908084671990431874381283363502795470282653297802934916155811881049844908319545009848393775227257052578591944993870073695755688436933812779613089230392569695253261620823676490316036551371447913932347169566988069},
     {2048,no,25195908475657893494027183240048398571429282126204032027777137836043662020707595556264018525880784406918290641249515082189298559149176184502808489120072844992687392807287776735971418347270261896375014971824691165077613379859095700097330459748808428401797429100642458691817195118746121515172654632282216869987549182422433637259085141865462043576798423387184774447920739934236584823824281198163815010674810451660377306056201619676256133844143603833904414952634432190114657544454178424020924616515723350778707749817125772467962926386356373289912154831438167899885040445364023527381951378636564391212010397122822120720357}
    ].
	
rsa_tests() ->
    [{I,J,dsize(K),is_probably_prime(K)} || {I,J,K} <- rsa_test_cases()].

dsize(K) when K < 10 -> 1;
dsize(K) -> 1 + dsize(K div 10).
 
    

%% def miller_rabin_prime?(n,k)
%%   return true if n == 2
%%   return false if n < 2 or n % 2 == 0
%%   d = n - 1
%%   s = 0
%%   while d % 2 == 0
%%     d /= 2
%%     s += 1
%%   end
%%   k.times do
%%     a = 2 + rand(n-4)
%%     x = (a**d) % n
%%     next if x == 1 or x == n-1
%%     for r in (1 .. s-1)
%%       x = (x**2) % n
%%       return false if x == 1
%%       break if x == n-1
%%     end
%%     return false if x != n-1
%%   end
%%   true  # probably
%% end
 
%% with maximal help from crypto

test() ->
    make_prime(1024).

test1() ->
    [I || I <- lists:seq(1, 1000), is_probably_prime(I)].

test2() ->
    N = 31987937737479355332620068643713101490952335301,
    A = lin:pow(2,N-1,N),
    {A,is_probably_prime(N)}.

test3() ->
    true = is_probably_prime(643808006803554439230129854961492699151386107534013432918073439524138264842370630061369715394739134090922937332590384720397133335969549256322620979036686633213903952966175107096769180017646161851573147596390153),
    false = is_probably_prime(743808006803554439230129854961492699151386107534013432918073439524138264842370630061369715394739134090922937332590384720397133335969549256322620979036686633213903952966175107096769180017646161851573147596390153),
    yes.


%% 200 decimal digits * 200 decimal digits = 400 decimal digits
%% = 400*3.32 = 1328 bits

%% say 154 decimal digits = 154*3.32 => 511 bits Two numbers = 1024 bits)

test4() ->
    A = make_prime(1024),
    B = make_prime(1024),
    false = is_probably_prime(A*B),
    {A*B,is_composite}.

-spec make_prime(LengthInBits::integer()) ->
			Prime::integer().


%% 768 bit keys are the current record
%%    call with 384

%% two 384 bit keys takes about 240 ms  (0.2 seconds)
%% 1024 bit (2 * 512) takes about 0.4 seconds
%% 2048 bit (2*1024) takes 2-3 seconds

make_prime(DLen) ->
    %% Len = length in bits
    Len1 = trunc(DLen/8) + 1,
    N = initial_prime(Len1, 1000),
    %% N is an odd number
    {_Time, {P,_Len,_Bits,_K}} = timer:tc(?MODULE, long_loop, [N, 0]),
    %% io:format("~p ~p (~p digits) (~p bits) Found in ~p iteractions~n",
    %% 	      [Time,P,Len,Bits,K]),
    P.

long_loop(P, K) ->
    case is_probably_prime(P) of
	true ->
	    Len = digits(P, 0),
	    Bits = trunc(Len*3.219),
	    {P,Len,Bits,K};
	false ->
	    long_loop(P+2, K+2)
    end.

digits(P, K) when P < 10 -> K+1;
digits(P, K) -> digits(P div 10, K+1).
 
    


initial_prime(_, 0) ->
    exit(too_may_tries);
initial_prime(Len, K) ->
    case (catch crypto:strong_rand_bytes(Len)) of
	{'EXIT', _} ->
	    initial_prime(Len, K-1);
	Bin ->
	    P = pint_to_int(Bin, 0),
	    case is_even(P) of
		true -> P+1;
		false -> P
	    end
    end.

pint_to_int(<<>>,N) -> N;
pint_to_int(<<X:8,B/binary>>,N) ->
    pint_to_int(B, N*256+X).

-spec is_probably_prime(integer()) -> boolean().

%% runs the rabbin miller rabit test 40 times
%% to test for a prime number

is_probably_prime(2) -> true;
is_probably_prime(N) when N < 2 -> false;
is_probably_prime(3) -> true;
is_probably_prime(5) -> true;
is_probably_prime(N) ->
    case is_even(N) of
	true -> false;
	false ->
	    {S, D} = sd(N-1, 0),
	    loop(40, N, S, D)
    end.

loop(0,_,_,_) ->
    true;
loop(K, N, S, D) ->
    A = 2 + crypto:rand_uniform(1,N-4),
    X = lin:pow(A,D,N),
    N1 = N - 1,
    case X of
	1  -> loop(K-1, N, S, D);
	N1 -> loop(K-1, N,S,D);
	_  -> inner(S-1, K, N, X, S, D)
    end.

inner(0, K, N, X, S, D) ->
    case N-1 of
	X -> loop(K-1, N, S, D);
	_ -> false
    end;
inner(R, K, N, X, S, D) ->
    X1 = lin:pow(X,2,N),
    N1 = N - 1,
    case X1 of
	1  -> false;
	N1 -> inner(0, K, N, X1, S, D);
	_  -> inner(R-1,K,N,X1,S,D)
    end.
		   
sd(K, N) ->
    case is_even(K) of
	true  -> sd(K div 2, N+1);
	false -> {N, K}
    end.
    
is_even(K) ->
    K band 1 == 0.

%% greatest common devisor

gcd(A, B) when A < B -> gcd(B, A);
gcd(A, 0) -> A;
gcd(A, B) -> gcd(B, A rem B).
