import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a batched program group.
    final class BatchedProgramGroupView {
        var codeText: String
        var labelText: String
        var maximumText: String
        var procedureCode: String
        var limitText: String
        var statusLabel: String

        init(codeText: String, labelText: String, maximumText: String, procedureCode: String, limitText: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.maximumText = maximumText
            self.procedureCode = procedureCode
            self.limitText = limitText
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedProgramGroupView(_ item: BatchedProgramGroup) -> BatchedProgramGroupView {
        return BatchedProgramGroupView(
            codeText: item.code,
            labelText: item.label,
            maximumText: String(format: "%.2f", item.maximum),
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 80),
            limitText: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedProgramGroupViews(_ items: [BatchedProgramGroup]) -> [BatchedProgramGroupView] {
        var views: [BatchedProgramGroupView] = []
        for item in items {
            views.append(toBatchedProgramGroupView(item))
        }
        return views
    }

    static func sumBatchedProgramGroupView(_ view: BatchedProgramGroupView) throws -> Double {
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return parsedMaximum + Double(parsedLimit)
    }
}
