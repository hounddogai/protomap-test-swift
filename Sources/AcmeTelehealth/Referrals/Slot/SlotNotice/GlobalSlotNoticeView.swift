import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a global slot notice.
    final class GlobalSlotNoticeView {
        var code: String
        var title: String
        var region: String
        var capacity: String
        var timezone: String
        var sequenceText: String
        var acuity: String
        var summaryText: String
        var statusLabel: String

        init(code: String, title: String, region: String, capacity: String, timezone: String, sequenceText: String, acuity: String, summaryText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.region = region
            self.capacity = capacity
            self.timezone = timezone
            self.sequenceText = sequenceText
            self.acuity = acuity
            self.summaryText = summaryText
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalSlotNoticeView(_ item: GlobalSlotNotice) -> GlobalSlotNoticeView {
        return GlobalSlotNoticeView(
            code: item.code,
            title: item.title,
            region: item.region,
            capacity: String(item.capacity),
            timezone: item.timezone,
            sequenceText: String(item.sequence),
            acuity: String(item.acuity),
            summaryText: item.summary,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalSlotNoticeViews(_ items: [GlobalSlotNotice]) -> [GlobalSlotNoticeView] {
        var views: [GlobalSlotNoticeView] = []
        for item in items {
            views.append(toGlobalSlotNoticeView(item))
        }
        return views
    }

    static func sumGlobalSlotNoticeView(_ view: GlobalSlotNoticeView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedCapacity) + Double(parsedSequence) + Double(parsedAcuity)
    }
}
