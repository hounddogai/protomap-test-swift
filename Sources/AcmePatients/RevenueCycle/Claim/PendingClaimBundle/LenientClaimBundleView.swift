import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a lenient claim bundle.
    final class LenientClaimBundleView {
        var code: String
        var label: String
        var retriesText: String
        var visible: String
        var ownerID: String
        var acuityText: String
        var diagnosisCode: String
        var visitMinutesText: String
        var dosageMg: String
        var batchSize: String
        var statusLabel: String

        init(code: String, label: String, retriesText: String, visible: String, ownerID: String, acuityText: String, diagnosisCode: String, visitMinutesText: String, dosageMg: String, batchSize: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.retriesText = retriesText
            self.visible = visible
            self.ownerID = ownerID
            self.acuityText = acuityText
            self.diagnosisCode = diagnosisCode
            self.visitMinutesText = visitMinutesText
            self.dosageMg = dosageMg
            self.batchSize = batchSize
            self.statusLabel = statusLabel
        }
    }

    static func toLenientClaimBundleView(_ item: LenientClaimBundle) -> LenientClaimBundleView {
        return LenientClaimBundleView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 80),
            retriesText: String(item.retries),
            visible: "\(item.visible)",
            ownerID: item.ownerID,
            acuityText: String(item.acuity),
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 120),
            visitMinutesText: String(item.visitMinutes),
            dosageMg: String(format: "%.2f", item.dosageMg),
            batchSize: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientClaimBundleViews(_ items: [LenientClaimBundle]) -> [LenientClaimBundleView] {
        var views: [LenientClaimBundleView] = []
        for item in items {
            views.append(toLenientClaimBundleView(item))
        }
        return views
    }

    static func sumLenientClaimBundleView(_ view: LenientClaimBundleView) throws -> Double {
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedRetries) + Double(parsedAcuity) + Double(parsedVisitMinutes)
    }
}
