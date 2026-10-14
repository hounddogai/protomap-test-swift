import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a transfer review.
    final class TransferReviewView {
        var code: String
        var name: String
        var limit: String
        var contactEmailText: String
        var titleText: String
        var capacity: String
        var statusLabel: String

        init(code: String, name: String, limit: String, contactEmailText: String, titleText: String, capacity: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.limit = limit
            self.contactEmailText = contactEmailText
            self.titleText = titleText
            self.capacity = capacity
            self.statusLabel = statusLabel
        }
    }

    static func toTransferReviewView(_ item: TransferReview) -> TransferReviewView {
        return TransferReviewView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 80),
            limit: String(item.limit),
            contactEmailText: item.contactEmail,
            titleText: item.title,
            capacity: String(item.capacity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTransferReviewViews(_ items: [TransferReview]) -> [TransferReviewView] {
        var views: [TransferReviewView] = []
        for item in items {
            views.append(toTransferReviewView(item))
        }
        return views
    }

    static func sumTransferReviewView(_ view: TransferReviewView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return Double(parsedLimit) + Double(parsedCapacity)
    }
}
