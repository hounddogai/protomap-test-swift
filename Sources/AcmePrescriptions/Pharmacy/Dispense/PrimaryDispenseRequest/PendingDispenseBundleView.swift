import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a pending dispense bundle.
    final class PendingDispenseBundleView {
        var code: String
        var name: String
        var procedureCodeText: String
        var ownerID: String
        var dosageMgText: String
        var specialty: String
        var priority: String
        var statusLabel: String

        init(code: String, name: String, procedureCodeText: String, ownerID: String, dosageMgText: String, specialty: String, priority: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.procedureCodeText = procedureCodeText
            self.ownerID = ownerID
            self.dosageMgText = dosageMgText
            self.specialty = specialty
            self.priority = priority
            self.statusLabel = statusLabel
        }
    }

    static func toPendingDispenseBundleView(_ item: PendingDispenseBundle) -> PendingDispenseBundleView {
        return PendingDispenseBundleView(
            code: Kit.Text.truncate(item.code, limit: 40),
            name: item.name,
            procedureCodeText: Kit.Text.truncate(item.procedureCode, limit: 40),
            ownerID: Kit.Text.truncate(item.ownerID, limit: 40),
            dosageMgText: String(format: "%.2f", item.dosageMg),
            specialty: item.specialty,
            priority: String(item.priority),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingDispenseBundleViews(_ items: [PendingDispenseBundle]) -> [PendingDispenseBundleView] {
        var views: [PendingDispenseBundleView] = []
        for item in items {
            views.append(toPendingDispenseBundleView(item))
        }
        return views
    }

    static func sumPendingDispenseBundleView(_ view: PendingDispenseBundleView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return parsedDosageMg + Double(parsedPriority)
    }
}
