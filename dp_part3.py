import sys

def R(n, s, c, r):
    BASECASE = -1
    SELECT = 1
    DISCARD = 0
    table = [[0]*(s + 1) for _ in range(n + 1)] #table[n+1][s+1]
    parent = [[0]*(s + 1) for _ in range(n + 1)] #parent table[n+1][s+1]

    #base
    for i in range(n + 1):
        table[i][0] = 0
        parent[i][0] = BASECASE
    for j in range(1, s + 1):
        table[0][j] = sys.maxsize
        parent[0][j] = BASECASE

    for i in range(1, n + 1): #policies
        for j in range(1, s + 1): #savings

            #include policy i
            if (j < c[i - 1]): 
                option1 = r[i - 1] #include
            else:
                option1 = table[i-1][j-c[i-1]] + r[i - 1] #include

            #exclude policy i
            option2 = table[i-1][j] #exclude
            
            #table[i][j] = min(option1, option2)
            if option1 < option2:
                table[i][j] = option1
                parent[i][j] = SELECT #include
            if option1 > option2:
                table[i][j] = option2
                parent[i][j] = DISCARD #exclude
            if option1 == option2: #tie breaking
                table[i][j] = option2
                parent[i][j] = DISCARD

    selectedPolicies = []
    i = n
    j = s
    while i > 0 and j > 0:
        if parent[i][j] == SELECT:
            selectedPolicies.append(i)
            j = j - c[i-1]
        i -= 1
    
    #prints out what my tables look like so I can double check and trace it myself
    #for i in range(n+1):
    #    for j in range(s+1):
    #        print(table[i][j], end=" ")
    #    print()

    #for i in range(n+1):
    #    for j in range(s+1):
    #        print(parent[i][j], end=" ")
    #    print()
    #print()

    riskSolution = table[n][s] 
    numPolicies = len(selectedPolicies)
    policies = sorted(selectedPolicies)

    print(riskSolution) #first line
    print(numPolicies) #second line
    for p in policies: #third line
        print(p, end=" ")

if __name__ == "__main__":
    n,s = map(int,input().split())
    c = list(map(int,input().split()))
    r = list(map(int, input().split()))

    if s > sum(c):
        print(-1)
    else:
        R(n, s, c, r)