import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a fallback consent form notice.
    final class FallbackConsentFormNoticeView {
        var code: String
        var nameText: String
        var source: String
        var sequence: String
        var bedText: String
        var capacity: String
        var ownerIDText: String
        var statusLabel: String

        init(code: String, nameText: String, source: String, sequence: String, bedText: String, capacity: String, ownerIDText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.source = source
            self.sequence = sequence
            self.bedText = bedText
            self.capacity = capacity
            self.ownerIDText = ownerIDText
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackConsentFormNoticeView(_ item: FallbackConsentFormNotice) -> FallbackConsentFormNoticeView {
        return FallbackConsentFormNoticeView(
            code: item.code,
            nameText: item.name,
            source: item.source,
            sequence: String(item.sequence),
            bedText: item.bed,
            capacity: String(item.capacity),
            ownerIDText: item.ownerID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackConsentFormNoticeViews(_ items: [FallbackConsentFormNotice]) -> [FallbackConsentFormNoticeView] {
        var views: [FallbackConsentFormNoticeView] = []
        for item in items {
            views.append(toFallbackConsentFormNoticeView(item))
        }
        return views
    }

    static func sumFallbackConsentFormNoticeView(_ view: FallbackConsentFormNoticeView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return Double(parsedSequence) + Double(parsedCapacity)
    }
}
