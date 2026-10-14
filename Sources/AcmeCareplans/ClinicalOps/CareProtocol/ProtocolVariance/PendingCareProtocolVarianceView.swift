import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a pending care protocol variance.
    final class PendingCareProtocolVarianceView {
        var code: String
        var label: String
        var floorValueText: String
        var durationMinutes: String
        var payer: String
        var region: String
        var createdAt: String
        var unitText: String
        var visible: String
        var phone: String
        var statusLabel: String

        init(code: String, label: String, floorValueText: String, durationMinutes: String, payer: String, region: String, createdAt: String, unitText: String, visible: String, phone: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.floorValueText = floorValueText
            self.durationMinutes = durationMinutes
            self.payer = payer
            self.region = region
            self.createdAt = createdAt
            self.unitText = unitText
            self.visible = visible
            self.phone = phone
            self.statusLabel = statusLabel
        }
    }

    static func toPendingCareProtocolVarianceView(_ item: PendingCareProtocolVariance) -> PendingCareProtocolVarianceView {
        return PendingCareProtocolVarianceView(
            code: item.code,
            label: item.label,
            floorValueText: String(format: "%.2f", item.floorValue),
            durationMinutes: String(item.durationMinutes),
            payer: item.payer,
            region: item.region,
            createdAt: String(item.createdAt),
            unitText: item.unit,
            visible: "\(item.visible)",
            phone: item.phone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingCareProtocolVarianceViews(_ items: [PendingCareProtocolVariance]) -> [PendingCareProtocolVarianceView] {
        var views: [PendingCareProtocolVarianceView] = []
        for item in items {
            views.append(toPendingCareProtocolVarianceView(item))
        }
        return views
    }

    static func sumPendingCareProtocolVarianceView(_ view: PendingCareProtocolVarianceView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return parsedFloorValue + Double(parsedDurationMinutes) + Double(parsedCreatedAt)
    }
}
