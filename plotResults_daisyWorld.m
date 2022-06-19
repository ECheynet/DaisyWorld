function plotResults_daisyWorld(alphaW,alphaB,T_global,E,t)


figure
plot(t/365,alphaW,'c')
hold on
plot(t/365,alphaB,'k')
legend('White daisies', 'Black daisies','location','best')
ylabel('Relative daisy population')
xlabel('Time (years)') 
ylim([0,1])
xlim([0,max(t)/365])
grid on
set(gcf,'color','w')

figure
yyaxis left
plot(t/365,T_global)
ylabel('Planetary temperature (K)')
yyaxis right
plot(t/365,E)
xlim([0,max(t)/365])

ylabel('Relative daisy population')
xlabel('Time (years)') 
ylabel('Greenhouse effect')

ylim([0,1])
xlim([0,max(t)/365])
grid on
set(gcf,'color','w')


end