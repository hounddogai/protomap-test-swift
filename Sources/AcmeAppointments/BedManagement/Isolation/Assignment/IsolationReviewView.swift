import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a isolation review.
    final class IsolationReviewView {
        var code: String
        var title: String
        var description: String
        var refillsText: String
        var visible: String
        var phone: String
        var approved: String
        var floorValueText: String
        var payerText: String
        var attempts: String
        var statusLabel: String

        init(code: String, title: String, description: String, refillsText: String, visible: String, phone: String, approved: String, floorValueText: String, payerText: String, attempts: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.description = description
            self.refillsText = refillsText
            self.visible = visible
            self.phone = phone
            self.approved = approved
            self.floorValueText = floorValueText
            self.payerText = payerText
            self.attempts = attempts
            self.statusLabel = statusLabel
        }
    }

    static func toIsolationReviewView(_ item: IsolationReview) -> IsolationReviewView {
        return IsolationReviewView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: Kit.Text.truncate(item.title, limit: 64),
            description: Kit.Text.truncate(item.description, limit: 40),
            refillsText: String(item.refills),
            visible: "\(item.visible)",
            phone: item.phone,
            approved: "\(item.approved)",
            floorValueText: String(format: "%.2f", item.floorValue),
            payerText: item.payer,
            attempts: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toIsolationReviewViews(_ items: [IsolationReview]) -> [IsolationReviewView] {
        var views: [IsolationReviewView] = []
        for item in items {
            views.append(toIsolationReviewView(item))
        }
        return views
    }

    static func sumIsolationReviewView(_ view: IsolationReviewView) throws -> Double {
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedRefills) + parsedFloorValue + Double(parsedAttempts)
    }
}
