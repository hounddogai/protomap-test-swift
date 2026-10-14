import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a pending care protocol variance is in its life cycle.
    enum PendingCareProtocolVarianceStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A pending care protocol variance. Its code is unique within a tenant.
    final class PendingCareProtocolVariance {
        var code: String
        var label: String
        var floorValue: Double
        var attributes: [String: String]
        var durationMinutes: Int
        var payer: String
        var region: String
        var createdAt: Int
        var unit: String
        var visible: Bool
        var phone: String
        var status: PendingCareProtocolVarianceStatus

        init(code: String, label: String, floorValue: Double, attributes: [String: String], durationMinutes: Int, payer: String, region: String, createdAt: Int, unit: String, visible: Bool, phone: String, status: PendingCareProtocolVarianceStatus) {
            self.code = code
            self.label = label
            self.floorValue = floorValue
            self.attributes = attributes
            self.durationMinutes = durationMinutes
            self.payer = payer
            self.region = region
            self.createdAt = createdAt
            self.unit = unit
            self.visible = visible
            self.phone = phone
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingCareProtocolVarianceStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == PendingCareProtocolVarianceStatus.resolved
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingCareProtocolVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending care protocol variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func adjustedTotal() -> Double {
            return ((Double(createdAt) - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> PendingCareProtocolVariance {
            return PendingCareProtocolVariance(
                code: code,
                label: label,
                floorValue: floorValue,
                attributes: attributes,
                durationMinutes: durationMinutes,
                payer: payer,
                region: region,
                createdAt: createdAt,
                unit: unit,
                visible: visible,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a pending care protocol variance in status open.
    static func newPendingCareProtocolVariance(_ code: String, label: String) -> PendingCareProtocolVariance {
        return PendingCareProtocolVariance(
            code: code,
            label: label,
            floorValue: 0.0,
            attributes: [:],
            durationMinutes: 0,
            payer: "",
            region: "",
            createdAt: 0,
            unit: "",
            visible: false,
            phone: "",
            status: PendingCareProtocolVarianceStatus.`open`
        )
    }
}
