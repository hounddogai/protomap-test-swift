import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a default transfer review.
    final class DefaultTransferReviewView {
        var codeText: String
        var nameText: String
        var ceiling: String
        var timezoneText: String
        var startsAt: String
        var ratio: String
        var maximumText: String
        var checksumText: String
        var titleText: String
        var copay: String
        var statusLabel: String

        init(codeText: String, nameText: String, ceiling: String, timezoneText: String, startsAt: String, ratio: String, maximumText: String, checksumText: String, titleText: String, copay: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.ceiling = ceiling
            self.timezoneText = timezoneText
            self.startsAt = startsAt
            self.ratio = ratio
            self.maximumText = maximumText
            self.checksumText = checksumText
            self.titleText = titleText
            self.copay = copay
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultTransferReviewView(_ item: DefaultTransferReview) -> DefaultTransferReviewView {
        return DefaultTransferReviewView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            nameText: item.name,
            ceiling: String(format: "%.2f", item.ceiling),
            timezoneText: item.timezone,
            startsAt: String(item.startsAt),
            ratio: String(format: "%.2f", item.ratio),
            maximumText: String(format: "%.2f", item.maximum),
            checksumText: item.checksum,
            titleText: item.title,
            copay: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultTransferReviewViews(_ items: [DefaultTransferReview]) -> [DefaultTransferReviewView] {
        var views: [DefaultTransferReviewView] = []
        for item in items {
            views.append(toDefaultTransferReviewView(item))
        }
        return views
    }

    static func sumDefaultTransferReviewView(_ view: DefaultTransferReviewView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedCeiling + Double(parsedStartsAt) + parsedRatio
    }
}
