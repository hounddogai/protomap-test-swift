import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a transfer segment.
    final class TransferSegmentView {
        var code: String
        var label: String
        var source: String
        var segment: String
        var expiresAt: String
        var acuity: String
        var countryText: String
        var allergyText: String
        var statusLabel: String

        init(code: String, label: String, source: String, segment: String, expiresAt: String, acuity: String, countryText: String, allergyText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.source = source
            self.segment = segment
            self.expiresAt = expiresAt
            self.acuity = acuity
            self.countryText = countryText
            self.allergyText = allergyText
            self.statusLabel = statusLabel
        }
    }

    static func toTransferSegmentView(_ item: TransferSegment) -> TransferSegmentView {
        return TransferSegmentView(
            code: item.code,
            label: item.label,
            source: item.source,
            segment: Kit.Text.truncate(item.segment, limit: 40),
            expiresAt: String(item.expiresAt),
            acuity: String(item.acuity),
            countryText: item.country,
            allergyText: item.allergy,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTransferSegmentViews(_ items: [TransferSegment]) -> [TransferSegmentView] {
        var views: [TransferSegmentView] = []
        for item in items {
            views.append(toTransferSegmentView(item))
        }
        return views
    }

    static func sumTransferSegmentView(_ view: TransferSegmentView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedExpiresAt) + Double(parsedAcuity)
    }
}
