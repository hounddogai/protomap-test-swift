import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a global isolation window.
    final class GlobalIsolationWindowView {
        var code: String
        var labelText: String
        var revision: String
        var dosageMg: String
        var visitMinutes: String
        var statusLabel: String

        init(code: String, labelText: String, revision: String, dosageMg: String, visitMinutes: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.revision = revision
            self.dosageMg = dosageMg
            self.visitMinutes = visitMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalIsolationWindowView(_ item: GlobalIsolationWindow) -> GlobalIsolationWindowView {
        return GlobalIsolationWindowView(
            code: item.code,
            labelText: item.label,
            revision: String(item.revision),
            dosageMg: String(format: "%.2f", item.dosageMg),
            visitMinutes: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalIsolationWindowViews(_ items: [GlobalIsolationWindow]) -> [GlobalIsolationWindowView] {
        var views: [GlobalIsolationWindowView] = []
        for item in items {
            views.append(toGlobalIsolationWindowView(item))
        }
        return views
    }

    static func sumGlobalIsolationWindowView(_ view: GlobalIsolationWindowView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedRevision) + parsedDosageMg + Double(parsedVisitMinutes)
    }
}
