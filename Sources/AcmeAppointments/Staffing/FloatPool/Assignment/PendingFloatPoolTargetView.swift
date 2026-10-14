import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a pending float pool target.
    final class PendingFloatPoolTargetView {
        var codeText: String
        var nameText: String
        var retriesText: String
        var durationMinutesText: String
        var reviewerText: String
        var channelText: String
        var summaryText: String
        var acuity: String
        var discount: String
        var endsAtText: String
        var statusLabel: String

        init(codeText: String, nameText: String, retriesText: String, durationMinutesText: String, reviewerText: String, channelText: String, summaryText: String, acuity: String, discount: String, endsAtText: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.retriesText = retriesText
            self.durationMinutesText = durationMinutesText
            self.reviewerText = reviewerText
            self.channelText = channelText
            self.summaryText = summaryText
            self.acuity = acuity
            self.discount = discount
            self.endsAtText = endsAtText
            self.statusLabel = statusLabel
        }
    }

    static func toPendingFloatPoolTargetView(_ item: PendingFloatPoolTarget) -> PendingFloatPoolTargetView {
        return PendingFloatPoolTargetView(
            codeText: item.code,
            nameText: item.name,
            retriesText: String(item.retries),
            durationMinutesText: String(item.durationMinutes),
            reviewerText: item.reviewer,
            channelText: Kit.Text.truncate(item.channel, limit: 64),
            summaryText: item.summary,
            acuity: String(item.acuity),
            discount: String(format: "%.2f", item.discount),
            endsAtText: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingFloatPoolTargetViews(_ items: [PendingFloatPoolTarget]) -> [PendingFloatPoolTargetView] {
        var views: [PendingFloatPoolTargetView] = []
        for item in items {
            views.append(toPendingFloatPoolTargetView(item))
        }
        return views
    }

    static func sumPendingFloatPoolTargetView(_ view: PendingFloatPoolTargetView) throws -> Double {
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedRetries) + Double(parsedDurationMinutes) + Double(parsedAcuity)
    }
}
