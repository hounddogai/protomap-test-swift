import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a program agreement.
    final class ProgramAgreementView {
        var code: String
        var labelText: String
        var marginText: String
        var summary: String
        var ratio: String
        var segment: String
        var sourceText: String
        var statusLabel: String

        init(code: String, labelText: String, marginText: String, summary: String, ratio: String, segment: String, sourceText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.marginText = marginText
            self.summary = summary
            self.ratio = ratio
            self.segment = segment
            self.sourceText = sourceText
            self.statusLabel = statusLabel
        }
    }

    static func toProgramAgreementView(_ item: ProgramAgreement) -> ProgramAgreementView {
        return ProgramAgreementView(
            code: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 80),
            marginText: String(format: "%.2f", item.margin),
            summary: Kit.Text.truncate(item.summary, limit: 64),
            ratio: String(format: "%.2f", item.ratio),
            segment: Kit.Text.truncate(item.segment, limit: 64),
            sourceText: Kit.Text.truncate(item.source, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toProgramAgreementViews(_ items: [ProgramAgreement]) -> [ProgramAgreementView] {
        var views: [ProgramAgreementView] = []
        for item in items {
            views.append(toProgramAgreementView(item))
        }
        return views
    }

    static func sumProgramAgreementView(_ view: ProgramAgreementView) throws -> Double {
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedMargin + parsedRatio
    }
}
