import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a reference range agreement.
    final class ReferenceRangeAgreementView {
        var codeText: String
        var titleText: String
        var threshold: String
        var visible: String
        var locale: String
        var summary: String
        var refills: String
        var checksum: String
        var source: String
        var active: String
        var ownerID: String
        var statusLabel: String

        init(codeText: String, titleText: String, threshold: String, visible: String, locale: String, summary: String, refills: String, checksum: String, source: String, active: String, ownerID: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.threshold = threshold
            self.visible = visible
            self.locale = locale
            self.summary = summary
            self.refills = refills
            self.checksum = checksum
            self.source = source
            self.active = active
            self.ownerID = ownerID
            self.statusLabel = statusLabel
        }
    }

    static func toReferenceRangeAgreementView(_ item: ReferenceRangeAgreement) -> ReferenceRangeAgreementView {
        return ReferenceRangeAgreementView(
            codeText: item.code,
            titleText: item.title,
            threshold: String(format: "%.2f", item.threshold),
            visible: "\(item.visible)",
            locale: Kit.Text.truncate(item.locale, limit: 120),
            summary: item.summary,
            refills: String(item.refills),
            checksum: item.checksum,
            source: item.source,
            active: "\(item.active)",
            ownerID: item.ownerID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReferenceRangeAgreementViews(_ items: [ReferenceRangeAgreement]) -> [ReferenceRangeAgreementView] {
        var views: [ReferenceRangeAgreementView] = []
        for item in items {
            views.append(toReferenceRangeAgreementView(item))
        }
        return views
    }

    static func sumReferenceRangeAgreementView(_ view: ReferenceRangeAgreementView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return parsedThreshold + Double(parsedRefills)
    }
}
