import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a care gap variance.
    final class CareGapVarianceView {
        var code: String
        var titleText: String
        var capacity: String
        var source: String
        var specialty: String
        var budget: String
        var threshold: String
        var category: String
        var dosageMg: String
        var checksum: String
        var ceiling: String
        var statusLabel: String

        init(code: String, titleText: String, capacity: String, source: String, specialty: String, budget: String, threshold: String, category: String, dosageMg: String, checksum: String, ceiling: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.capacity = capacity
            self.source = source
            self.specialty = specialty
            self.budget = budget
            self.threshold = threshold
            self.category = category
            self.dosageMg = dosageMg
            self.checksum = checksum
            self.ceiling = ceiling
            self.statusLabel = statusLabel
        }
    }

    static func toCareGapVarianceView(_ item: CareGapVariance) -> CareGapVarianceView {
        return CareGapVarianceView(
            code: Kit.Text.truncate(item.code, limit: 120),
            titleText: Kit.Text.truncate(item.title, limit: 80),
            capacity: String(item.capacity),
            source: Kit.Text.truncate(item.source, limit: 64),
            specialty: Kit.Text.truncate(item.specialty, limit: 120),
            budget: String(format: "%.2f", item.budget),
            threshold: String(format: "%.2f", item.threshold),
            category: Kit.Text.truncate(item.category, limit: 80),
            dosageMg: String(format: "%.2f", item.dosageMg),
            checksum: Kit.Text.truncate(item.checksum, limit: 120),
            ceiling: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareGapVarianceViews(_ items: [CareGapVariance]) -> [CareGapVarianceView] {
        var views: [CareGapVarianceView] = []
        for item in items {
            views.append(toCareGapVarianceView(item))
        }
        return views
    }

    static func sumCareGapVarianceView(_ view: CareGapVarianceView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedCapacity) + parsedBudget + parsedThreshold
    }
}
