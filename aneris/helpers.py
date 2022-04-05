import aneris
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns


def export_results(hist, model, harmonized, metadata, file_name, unit = "Mt CO2/yr"):
    
    h = pd.concat([hist, model, harmonized])
    h['Label'] = h['Model'] + ' ' + h['Variable'] + ' ' + h['harmonize_year'] + ' ' + h['method']
    h.loc[h.Label.isna(), 'Label'] = h[h.Label.isna()]['Model'] + ' ' + h[h.Label.isna()]['Variable']
    h['Unit'] = unit
    h = h[h.Region.isin(['DEU'])]
    h = pd.melt(h, id_vars=["Label", "Model", "Scenario", "Region", "Variable", "Unit", "method"], 
                value_vars=h.columns[5:-3], var_name='Year', value_name='Emissions')   
    
    with pd.ExcelWriter('output/' + file_name) as writer:  
        h.to_excel(writer, sheet_name='data')
        metadata.to_excel(writer, sheet_name='metadata')
    
    return h


def plot(h):

    sns.lineplot(x=h.Year.astype(int), y=h.Emissions, hue=h.Label)
    plt.legend(bbox_to_anchor=(1.05, 1))
