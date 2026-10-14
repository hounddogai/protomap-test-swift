import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a modality variance.
    final class ModalityVarianceView {
        var codeText: String
        var label: String
        var capacity: String
        var patientRef: String
        var graceDaysText: String
        var refills: String
        var createdAt: String
        var statusLabel: String

        init(codeText: String, label: String, capacity: String, patientRef: String, graceDaysText: String, refills: String, createdAt: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.capacity = capacity
            self.patientRef = patientRef
            self.graceDaysText = graceDaysText
            self.refills = refills
            self.createdAt = createdAt
            self.statusLabel = statusLabel
        }
    }

    static func toModalityVarianceView(_ item: ModalityVariance) -> ModalityVarianceView {
        return ModalityVarianceView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 120),
            capacity: String(item.capacity),
            patientRef: item.patientRef,
            graceDaysText: String(item.graceDays),
            refills: String(item.refills),
            createdAt: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toModalityVarianceViews(_ items: [ModalityVariance]) -> [ModalityVarianceView] {
        var views: [ModalityVarianceView] = []
        for item in items {
            views.append(toModalityVarianceView(item))
        }
        return views
    }

    static func sumModalityVarianceView(_ view: ModalityVarianceView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedCapacity) + Double(parsedGraceDays) + Double(parsedRefills)
    }
}
