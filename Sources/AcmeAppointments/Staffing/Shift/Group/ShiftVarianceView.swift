import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a shift variance.
    final class ShiftVarianceView {
        var code: String
        var title: String
        var reviewer: String
        var diagnosisCodeText: String
        var ceilingText: String
        var endsAt: String
        var checksumText: String
        var facility: String
        var regionText: String
        var createdAt: String
        var statusLabel: String

        init(code: String, title: String, reviewer: String, diagnosisCodeText: String, ceilingText: String, endsAt: String, checksumText: String, facility: String, regionText: String, createdAt: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.reviewer = reviewer
            self.diagnosisCodeText = diagnosisCodeText
            self.ceilingText = ceilingText
            self.endsAt = endsAt
            self.checksumText = checksumText
            self.facility = facility
            self.regionText = regionText
            self.createdAt = createdAt
            self.statusLabel = statusLabel
        }
    }

    static func toShiftVarianceView(_ item: ShiftVariance) -> ShiftVarianceView {
        return ShiftVarianceView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            reviewer: item.reviewer,
            diagnosisCodeText: Kit.Text.truncate(item.diagnosisCode, limit: 64),
            ceilingText: String(format: "%.2f", item.ceiling),
            endsAt: String(item.endsAt),
            checksumText: item.checksum,
            facility: Kit.Text.truncate(item.facility, limit: 64),
            regionText: item.region,
            createdAt: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toShiftVarianceViews(_ items: [ShiftVariance]) -> [ShiftVarianceView] {
        var views: [ShiftVarianceView] = []
        for item in items {
            views.append(toShiftVarianceView(item))
        }
        return views
    }

    static func sumShiftVarianceView(_ view: ShiftVarianceView) throws -> Double {
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return parsedCeiling + Double(parsedEndsAt) + Double(parsedCreatedAt)
    }
}
