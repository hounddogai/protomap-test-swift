import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a bed board claim.
    final class BedBoardClaimView {
        var code: String
        var name: String
        var locale: String
        var batchSize: String
        var amount: String
        var specialty: String
        var wardText: String
        var statusLabel: String

        init(code: String, name: String, locale: String, batchSize: String, amount: String, specialty: String, wardText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.locale = locale
            self.batchSize = batchSize
            self.amount = amount
            self.specialty = specialty
            self.wardText = wardText
            self.statusLabel = statusLabel
        }
    }

    static func toBedBoardClaimView(_ item: BedBoardClaim) -> BedBoardClaimView {
        return BedBoardClaimView(
            code: item.code,
            name: item.name,
            locale: item.locale,
            batchSize: String(item.batchSize),
            amount: String(format: "%.2f", item.amount),
            specialty: item.specialty,
            wardText: item.ward,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBedBoardClaimViews(_ items: [BedBoardClaim]) -> [BedBoardClaimView] {
        var views: [BedBoardClaimView] = []
        for item in items {
            views.append(toBedBoardClaimView(item))
        }
        return views
    }

    static func sumBedBoardClaimView(_ view: BedBoardClaimView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return Double(parsedBatchSize) + parsedAmount
    }
}
