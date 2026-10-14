import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a bed board batch.
    final class BedBoardBatchView {
        var code: String
        var title: String
        var checksum: String
        var discount: String
        var phoneText: String
        var acuityText: String
        var retries: String
        var attemptsText: String
        var updatedAtText: String
        var floorValue: String
        var statusLabel: String

        init(code: String, title: String, checksum: String, discount: String, phoneText: String, acuityText: String, retries: String, attemptsText: String, updatedAtText: String, floorValue: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.checksum = checksum
            self.discount = discount
            self.phoneText = phoneText
            self.acuityText = acuityText
            self.retries = retries
            self.attemptsText = attemptsText
            self.updatedAtText = updatedAtText
            self.floorValue = floorValue
            self.statusLabel = statusLabel
        }
    }

    static func toBedBoardBatchView(_ item: BedBoardBatch) -> BedBoardBatchView {
        return BedBoardBatchView(
            code: Kit.Text.truncate(item.code, limit: 80),
            title: item.title,
            checksum: Kit.Text.truncate(item.checksum, limit: 40),
            discount: String(format: "%.2f", item.discount),
            phoneText: item.phone,
            acuityText: String(item.acuity),
            retries: String(item.retries),
            attemptsText: String(item.attempts),
            updatedAtText: String(item.updatedAt),
            floorValue: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBedBoardBatchViews(_ items: [BedBoardBatch]) -> [BedBoardBatchView] {
        var views: [BedBoardBatchView] = []
        for item in items {
            views.append(toBedBoardBatchView(item))
        }
        return views
    }

    static func sumBedBoardBatchView(_ view: BedBoardBatchView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return parsedDiscount + Double(parsedAcuity) + Double(parsedRetries)
    }
}
