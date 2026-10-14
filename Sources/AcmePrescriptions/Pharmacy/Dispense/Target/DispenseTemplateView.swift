import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a dispense template.
    final class DispenseTemplateView {
        var codeText: String
        var nameText: String
        var checksum: String
        var reviewer: String
        var ownerID: String
        var facilityText: String
        var retries: String
        var batchSizeText: String
        var sourceText: String
        var statusLabel: String

        init(codeText: String, nameText: String, checksum: String, reviewer: String, ownerID: String, facilityText: String, retries: String, batchSizeText: String, sourceText: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.checksum = checksum
            self.reviewer = reviewer
            self.ownerID = ownerID
            self.facilityText = facilityText
            self.retries = retries
            self.batchSizeText = batchSizeText
            self.sourceText = sourceText
            self.statusLabel = statusLabel
        }
    }

    static func toDispenseTemplateView(_ item: DispenseTemplate) -> DispenseTemplateView {
        return DispenseTemplateView(
            codeText: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 64),
            checksum: item.checksum,
            reviewer: item.reviewer,
            ownerID: item.ownerID,
            facilityText: item.facility,
            retries: String(item.retries),
            batchSizeText: String(item.batchSize),
            sourceText: item.source,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDispenseTemplateViews(_ items: [DispenseTemplate]) -> [DispenseTemplateView] {
        var views: [DispenseTemplateView] = []
        for item in items {
            views.append(toDispenseTemplateView(item))
        }
        return views
    }

    static func sumDispenseTemplateView(_ view: DispenseTemplateView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedRetries) + Double(parsedBatchSize)
    }
}
