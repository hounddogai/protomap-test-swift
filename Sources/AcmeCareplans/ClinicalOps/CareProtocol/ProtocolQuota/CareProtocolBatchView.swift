import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a care protocol batch.
    final class CareProtocolBatchView {
        var codeText: String
        var nameText: String
        var acuity: String
        var revisionText: String
        var weightText: String
        var ownerIDText: String
        var copay: String
        var statusLabel: String

        init(codeText: String, nameText: String, acuity: String, revisionText: String, weightText: String, ownerIDText: String, copay: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.acuity = acuity
            self.revisionText = revisionText
            self.weightText = weightText
            self.ownerIDText = ownerIDText
            self.copay = copay
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolBatchView(_ item: CareProtocolBatch) -> CareProtocolBatchView {
        return CareProtocolBatchView(
            codeText: item.code,
            nameText: item.name,
            acuity: String(item.acuity),
            revisionText: String(item.revision),
            weightText: String(format: "%.2f", item.weight),
            ownerIDText: item.ownerID,
            copay: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolBatchViews(_ items: [CareProtocolBatch]) -> [CareProtocolBatchView] {
        var views: [CareProtocolBatchView] = []
        for item in items {
            views.append(toCareProtocolBatchView(item))
        }
        return views
    }

    static func sumCareProtocolBatchView(_ view: CareProtocolBatchView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return Double(parsedAcuity) + Double(parsedRevision) + parsedWeight
    }
}
