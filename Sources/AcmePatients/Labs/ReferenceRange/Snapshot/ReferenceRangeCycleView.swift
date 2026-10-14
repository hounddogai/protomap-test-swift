import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a reference range cycle.
    final class ReferenceRangeCycleView {
        var code: String
        var label: String
        var createdAt: String
        var limit: String
        var revision: String
        var channel: String
        var segmentText: String
        var pinnedText: String
        var payerText: String
        var statusLabel: String

        init(code: String, label: String, createdAt: String, limit: String, revision: String, channel: String, segmentText: String, pinnedText: String, payerText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.createdAt = createdAt
            self.limit = limit
            self.revision = revision
            self.channel = channel
            self.segmentText = segmentText
            self.pinnedText = pinnedText
            self.payerText = payerText
            self.statusLabel = statusLabel
        }
    }

    static func toReferenceRangeCycleView(_ item: ReferenceRangeCycle) -> ReferenceRangeCycleView {
        return ReferenceRangeCycleView(
            code: item.code,
            label: item.label,
            createdAt: String(item.createdAt),
            limit: String(item.limit),
            revision: String(item.revision),
            channel: item.channel,
            segmentText: item.segment,
            pinnedText: "\(item.pinned)",
            payerText: item.payer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReferenceRangeCycleViews(_ items: [ReferenceRangeCycle]) -> [ReferenceRangeCycleView] {
        var views: [ReferenceRangeCycleView] = []
        for item in items {
            views.append(toReferenceRangeCycleView(item))
        }
        return views
    }

    static func sumReferenceRangeCycleView(_ view: ReferenceRangeCycleView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return Double(parsedCreatedAt) + Double(parsedLimit) + Double(parsedRevision)
    }
}
