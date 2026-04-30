import Foundation

public enum AppConstants {
    public static let appGroupID = "group.com.scrollcap.shared"
    public static let bundleID = "com.ethanshen.scrollcap"

    public enum UserDefaultsKeys {
        public static let captureCount = "captureCount"
        public static let isBroadcasting = "isBroadcasting"
        public static let latestFrameTimestamp = "latestFrameTimestamp"
        public static let broadcastFrameData = "broadcastFrameData"
    }

    public enum URLSchemes {
        public static let base = "scrollcap"
        public static let capture = "scrollcap://capture"
        public static let paymentSuccess = "scrollcap://payment/success"
        public static let paymentCancel = "scrollcap://payment/cancel"
    }
}
