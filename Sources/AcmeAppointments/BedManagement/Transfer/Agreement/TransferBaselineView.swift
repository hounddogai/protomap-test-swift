import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a transfer baseline.
    final class TransferBaselineView {
        var codeText: String
        var labelText: String
        var visibleText: String
        var minimum: String
        var patientRef: String
        var ward: String
        var channelText: String
        var archived: String
        var maximum: String
        var copay: String
        var dosageMg: String
        var statusLabel: String

        init(codeText: String, labelText: String, visibleText: String, minimum: String, patientRef: String, ward: String, channelText: String, archived: String, maximum: String, copay: String, dosageMg: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.visibleText = visibleText
            self.minimum = minimum
            self.patientRef = patientRef
            self.ward = ward
            self.channelText = channelText
            self.archived = archived
            self.maximum = maximum
            self.copay = copay
            self.dosageMg = dosageMg
            self.statusLabel = statusLabel
        }
    }

    static func toTransferBaselineView(_ item: TransferBaseline) -> TransferBaselineView {
        return TransferBaselineView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            labelText: Kit.Text.truncate(item.label, limit: 80),
            visibleText: "\(item.visible)",
            minimum: String(format: "%.2f", item.minimum),
            patientRef: item.patientRef,
            ward: item.ward,
            channelText: item.channel,
            archived: "\(item.archived)",
            maximum: String(format: "%.2f", item.maximum),
            copay: String(format: "%.2f", item.copay),
            dosageMg: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTransferBaselineViews(_ items: [TransferBaseline]) -> [TransferBaselineView] {
        var views: [TransferBaselineView] = []
        for item in items {
            views.append(toTransferBaselineView(item))
        }
        return views
    }

    static func sumTransferBaselineView(_ view: TransferBaselineView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedMinimum + parsedMaximum + parsedCopay
    }
}
