import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a batched care gap bundle is in its life cycle.
    enum BatchedCareGapBundleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A batched care gap bundle. Its code is unique within a tenant.
    final class BatchedCareGapBundle {
        var code: String
        var name: String
        var ratio: Double
        var attempts: Int
        var margin: Double
        var weight: Double
        var archived: Bool
        var country: String
        var retries: Int
        var ward: String
        var status: BatchedCareGapBundleStatus

        init(code: String, name: String, ratio: Double, attempts: Int, margin: Double, weight: Double, archived: Bool, country: String, retries: Int, ward: String, status: BatchedCareGapBundleStatus) {
            self.code = code
            self.name = name
            self.ratio = ratio
            self.attempts = attempts
            self.margin = margin
            self.weight = weight
            self.archived = archived
            self.country = country
            self.retries = retries
            self.ward = ward
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

        func canMoveTo(_ next: BatchedCareGapBundleStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == BatchedCareGapBundleStatus.expired
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

        func moveTo(_ next: BatchedCareGapBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched care gap bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func projectedTotal() -> Double {
            return ((margin - Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedCareGapBundle {
            return BatchedCareGapBundle(
                code: code,
                name: name,
                ratio: ratio,
                attempts: attempts,
                margin: margin,
                weight: weight,
                archived: archived,
                country: country,
                retries: retries,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a batched care gap bundle in status requested.
    static func newBatchedCareGapBundle(_ code: String, name: String) -> BatchedCareGapBundle {
        return BatchedCareGapBundle(
            code: code,
            name: name,
            ratio: 0.0,
            attempts: 0,
            margin: 0.0,
            weight: 0.0,
            archived: false,
            country: "",
            retries: 0,
            ward: "",
            status: BatchedCareGapBundleStatus.requested
        )
    }
}
