import AcmePlatform
import Foundation

extension Imaging {
    /// Where a fallback worklist request is in its life cycle.
    enum FallbackWorklistRequestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A fallback worklist request. Its code is unique within a tenant.
    final class FallbackWorklistRequest {
        var code: String
        var label: String
        var archived: Bool
        var region: String
        var margin: Double
        var cost: Double
        var country: String
        var phone: String
        var checksum: String
        var category: String
        var status: FallbackWorklistRequestStatus

        init(code: String, label: String, archived: Bool, region: String, margin: Double, cost: Double, country: String, phone: String, checksum: String, category: String, status: FallbackWorklistRequestStatus) {
            self.code = code
            self.label = label
            self.archived = archived
            self.region = region
            self.margin = margin
            self.cost = cost
            self.country = country
            self.phone = phone
            self.checksum = checksum
            self.category = category
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackWorklistRequestStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == FallbackWorklistRequestStatus.done
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == FallbackWorklistRequestStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackWorklistRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback worklist request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netValue() -> Double {
            return (cost * margin * 100).rounded() / 100
        }

        func copyValue() -> FallbackWorklistRequest {
            return FallbackWorklistRequest(
                code: code,
                label: label,
                archived: archived,
                region: region,
                margin: margin,
                cost: cost,
                country: country,
                phone: phone,
                checksum: checksum,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a fallback worklist request in status new.
    static func newFallbackWorklistRequest(_ code: String, label: String) -> FallbackWorklistRequest {
        return FallbackWorklistRequest(
            code: code,
            label: label,
            archived: false,
            region: "",
            margin: 0.0,
            cost: 0.0,
            country: "",
            phone: "",
            checksum: "",
            category: "",
            status: FallbackWorklistRequestStatus.new
        )
    }
}
