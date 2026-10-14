import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a care protocol allocation.
    final class CareProtocolAllocationView {
        var codeText: String
        var nameText: String
        var dosageMg: String
        var retries: String
        var sequence: String
        var quantityText: String
        var description: String
        var batchSize: String
        var windowDays: String
        var statusLabel: String

        init(codeText: String, nameText: String, dosageMg: String, retries: String, sequence: String, quantityText: String, description: String, batchSize: String, windowDays: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.dosageMg = dosageMg
            self.retries = retries
            self.sequence = sequence
            self.quantityText = quantityText
            self.description = description
            self.batchSize = batchSize
            self.windowDays = windowDays
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolAllocationView(_ item: CareProtocolAllocation) -> CareProtocolAllocationView {
        return CareProtocolAllocationView(
            codeText: item.code,
            nameText: item.name,
            dosageMg: String(format: "%.2f", item.dosageMg),
            retries: String(item.retries),
            sequence: String(item.sequence),
            quantityText: String(item.quantity),
            description: item.description,
            batchSize: String(item.batchSize),
            windowDays: String(item.windowDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolAllocationViews(_ items: [CareProtocolAllocation]) -> [CareProtocolAllocationView] {
        var views: [CareProtocolAllocationView] = []
        for item in items {
            views.append(toCareProtocolAllocationView(item))
        }
        return views
    }

    static func sumCareProtocolAllocationView(_ view: CareProtocolAllocationView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return parsedDosageMg + Double(parsedRetries) + Double(parsedSequence)
    }
}
