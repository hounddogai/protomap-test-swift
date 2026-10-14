import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a reference range profile.
    final class ReferenceRangeProfileView {
        var codeText: String
        var name: String
        var payerText: String
        var segment: String
        var marginText: String
        var createdAt: String
        var patientRefText: String
        var minimumText: String
        var limit: String
        var statusLabel: String

        init(codeText: String, name: String, payerText: String, segment: String, marginText: String, createdAt: String, patientRefText: String, minimumText: String, limit: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.payerText = payerText
            self.segment = segment
            self.marginText = marginText
            self.createdAt = createdAt
            self.patientRefText = patientRefText
            self.minimumText = minimumText
            self.limit = limit
            self.statusLabel = statusLabel
        }
    }

    static func toReferenceRangeProfileView(_ item: ReferenceRangeProfile) -> ReferenceRangeProfileView {
        return ReferenceRangeProfileView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 120),
            payerText: item.payer,
            segment: item.segment,
            marginText: String(format: "%.2f", item.margin),
            createdAt: String(item.createdAt),
            patientRefText: item.patientRef,
            minimumText: String(format: "%.2f", item.minimum),
            limit: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReferenceRangeProfileViews(_ items: [ReferenceRangeProfile]) -> [ReferenceRangeProfileView] {
        var views: [ReferenceRangeProfileView] = []
        for item in items {
            views.append(toReferenceRangeProfileView(item))
        }
        return views
    }

    static func sumReferenceRangeProfileView(_ view: ReferenceRangeProfileView) throws -> Double {
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return parsedMargin + Double(parsedCreatedAt) + parsedMinimum
    }
}
