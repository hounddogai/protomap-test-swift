import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a proxy draft.
    final class ProxyDraftView {
        var codeText: String
        var name: String
        var durationMinutes: String
        var limit: String
        var summaryText: String
        var ownerIDText: String
        var attemptsText: String
        var payer: String
        var versionText: String
        var budget: String
        var visitMinutes: String
        var statusLabel: String

        init(codeText: String, name: String, durationMinutes: String, limit: String, summaryText: String, ownerIDText: String, attemptsText: String, payer: String, versionText: String, budget: String, visitMinutes: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.durationMinutes = durationMinutes
            self.limit = limit
            self.summaryText = summaryText
            self.ownerIDText = ownerIDText
            self.attemptsText = attemptsText
            self.payer = payer
            self.versionText = versionText
            self.budget = budget
            self.visitMinutes = visitMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toProxyDraftView(_ item: ProxyDraft) -> ProxyDraftView {
        return ProxyDraftView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            name: item.name,
            durationMinutes: String(item.durationMinutes),
            limit: String(item.limit),
            summaryText: item.summary,
            ownerIDText: item.ownerID,
            attemptsText: String(item.attempts),
            payer: item.payer,
            versionText: String(item.version),
            budget: String(format: "%.2f", item.budget),
            visitMinutes: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toProxyDraftViews(_ items: [ProxyDraft]) -> [ProxyDraftView] {
        var views: [ProxyDraftView] = []
        for item in items {
            views.append(toProxyDraftView(item))
        }
        return views
    }

    static func sumProxyDraftView(_ view: ProxyDraftView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedDurationMinutes) + Double(parsedLimit) + Double(parsedAttempts)
    }
}
