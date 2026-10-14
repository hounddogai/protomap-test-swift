import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a adaptive care protocol profile.
    final class AdaptiveCareProtocolProfileView {
        var codeText: String
        var title: String
        var dosageMg: String
        var ownerID: String
        var segmentText: String
        var facilityText: String
        var channel: String
        var statusLabel: String

        init(codeText: String, title: String, dosageMg: String, ownerID: String, segmentText: String, facilityText: String, channel: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.dosageMg = dosageMg
            self.ownerID = ownerID
            self.segmentText = segmentText
            self.facilityText = facilityText
            self.channel = channel
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveCareProtocolProfileView(_ item: AdaptiveCareProtocolProfile) -> AdaptiveCareProtocolProfileView {
        return AdaptiveCareProtocolProfileView(
            codeText: item.code,
            title: item.title,
            dosageMg: String(format: "%.2f", item.dosageMg),
            ownerID: Kit.Text.truncate(item.ownerID, limit: 64),
            segmentText: item.segment,
            facilityText: item.facility,
            channel: Kit.Text.truncate(item.channel, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveCareProtocolProfileViews(_ items: [AdaptiveCareProtocolProfile]) -> [AdaptiveCareProtocolProfileView] {
        var views: [AdaptiveCareProtocolProfileView] = []
        for item in items {
            views.append(toAdaptiveCareProtocolProfileView(item))
        }
        return views
    }

    static func sumAdaptiveCareProtocolProfileView(_ view: AdaptiveCareProtocolProfileView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedDosageMg
    }
}
