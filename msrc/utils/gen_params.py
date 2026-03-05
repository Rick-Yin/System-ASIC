import numpy as np

def GetSubCarrierFD(fs, NCH):
    # fs: start frequency, MHz
    # NCH: indef of channels width
    if fs == 2400 and NCH in [1, 2, 3, 4]:
        return np.array([fs + 0.460 - 0.300 + NCH * 9.960 + n * 19.920 for n in range(0, 5 - NCH)]) * 1e6
    if fs == 5150 and NCH in [1, 2, 4, 5, 6, 8, 10]:
        return np.array([fs + 0.700 - 0.300 + NCH * 9.960 + n * 19.920 for n in range(0, 11 - NCH)]) * 1e6
    if fs == 5470 and NCH in [1, 2, 4, 5, 6, 8, 10, 12]:
        return np.array([fs + 0.780 - 0.300 + NCH * 9.960 + n * 19.920 for n in range(0, 13 - NCH)]) * 1e6
    if fs == 5725 and NCH in [1, 2, 3, 4, 5, 6]:
        return np.array([fs + 0.540 - 0.300 + NCH * 9.960 + n * 19.920 for n in range(0, 7 - NCH)]) * 1e6
    if fs == 5925 and NCH in [1, 2, 4, 5, 6, 8, 10, 25]:
        return np.array([fs + 1.300 - 0.300 + NCH * 9.960 + n * 19.920 for n in range(0, 26 - NCH)]) * 1e6
    if fs == 7163 and NCH in [1, 2, 4, 8, 10]:
        return np.array([fs + 2.800 - 1.200 + NCH * 39.840 + n * 79.680 for n in range(0, 21 - NCH)]) * 1e6
    raise ValueError('Invalid fs or NCH')

if __name__ == '__main__':
    num = 0
    # for fs in [2400, 5150, 5470, 5725, 5925, 7163]:
    #     for NCH in [1]:
    #         num += len(GetSubCarrierFD(fs, NCH))
    # print(num)
    print(GetSubCarrierFD(5150, 2)/1e6 - 5150)