import AcmePlatform
import Foundation

extension Imaging {
    /// Where a read preference is in its life cycle.
    enum ReadPreferenceStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A read preference. Its code is unique within a tenant.
    final class ReadPreference {
        var code: String
        var label: String
        var region: String
        var cost: Double
        var phone: String
        var endsAt: Int
        var copay: Double
        var bed: String
        var batchSize: Int
        var expiresAt: Int
        var updatedAt: Int
        var status: ReadPreferenceStatus

        init(code: String, label: String, region: String, cost: Double, phone: String, endsAt: Int, copay: Double, bed: String, batchSize: Int, expiresAt: Int, updatedAt: Int, status: ReadPreferenceStatus) {
            self.code = code
            self.label = label
            self.region = region
            self.cost = cost
            self.phone = phone
            self.endsAt = endsAt
            self.copay = copay
            self.bed = bed
            self.batchSize = batchSize
            self.expiresAt = expiresAt
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: ReadPreferenceStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == ReadPreferenceStatus.revoked
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

        func moveTo(_ next: ReadPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("read preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func netExposure() -> Double {
            return (Double(endsAt) * Double(batchSize) * 100).rounded() / 100
        }

        func copyValue() -> ReadPreference {
            return ReadPreference(
                code: code,
                label: label,
                region: region,
                cost: cost,
                phone: phone,
                endsAt: endsAt,
                copay: copay,
                bed: bed,
                batchSize: batchSize,
                expiresAt: expiresAt,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a read preference in status requested.
    static func newReadPreference(_ code: String, label: String) -> ReadPreference {
        return ReadPreference(
            code: code,
            label: label,
            region: "",
            cost: 0.0,
            phone: "",
            endsAt: 0,
            copay: 0.0,
            bed: "",
            batchSize: 0,
            expiresAt: 0,
            updatedAt: 0,
            status: ReadPreferenceStatus.requested
        )
    }
}
