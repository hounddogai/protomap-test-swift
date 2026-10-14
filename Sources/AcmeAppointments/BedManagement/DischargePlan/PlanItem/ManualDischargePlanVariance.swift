import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a manual discharge plan variance is in its life cycle.
    enum ManualDischargePlanVarianceStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A manual discharge plan variance. Its code is unique within a tenant.
    final class ManualDischargePlanVariance {
        var code: String
        var label: String
        var expiresAt: Int
        var segment: String
        var category: String
        var maximum: Double
        var tags: [String]
        var quantity: Int
        var channel: String
        var bed: String
        var procedureCode: String
        var status: ManualDischargePlanVarianceStatus

        init(code: String, label: String, expiresAt: Int, segment: String, category: String, maximum: Double, tags: [String], quantity: Int, channel: String, bed: String, procedureCode: String, status: ManualDischargePlanVarianceStatus) {
            self.code = code
            self.label = label
            self.expiresAt = expiresAt
            self.segment = segment
            self.category = category
            self.maximum = maximum
            self.tags = tags
            self.quantity = quantity
            self.channel = channel
            self.bed = bed
            self.procedureCode = procedureCode
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ManualDischargePlanVarianceStatus) -> Bool {
            switch status {
            case .requested:
                return next == ManualDischargePlanVarianceStatus.granted || next == ManualDischargePlanVarianceStatus.revoked
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: ManualDischargePlanVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual discharge plan variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedTotal() -> Double {
            return (maximum * Double(expiresAt) * 100).rounded() / 100
        }

        func copyValue() -> ManualDischargePlanVariance {
            return ManualDischargePlanVariance(
                code: code,
                label: label,
                expiresAt: expiresAt,
                segment: segment,
                category: category,
                maximum: maximum,
                tags: tags,
                quantity: quantity,
                channel: channel,
                bed: bed,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a manual discharge plan variance in status requested.
    static func newManualDischargePlanVariance(_ code: String, label: String) -> ManualDischargePlanVariance {
        return ManualDischargePlanVariance(
            code: code,
            label: label,
            expiresAt: 0,
            segment: "",
            category: "",
            maximum: 0.0,
            tags: [],
            quantity: 0,
            channel: "",
            bed: "",
            procedureCode: "",
            status: ManualDischargePlanVarianceStatus.requested
        )
    }
}
