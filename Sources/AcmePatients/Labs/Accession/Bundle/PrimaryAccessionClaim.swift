import AcmePlatform
import Foundation

extension Labs {
    /// Where a primary accession claim is in its life cycle.
    enum PrimaryAccessionClaimStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A primary accession claim. Its code is unique within a tenant.
    final class PrimaryAccessionClaim {
        var code: String
        var name: String
        var attempts: Int
        var category: String
        var phone: String
        var locale: String
        var approved: Bool
        var version: Int
        var specialty: String
        var status: PrimaryAccessionClaimStatus

        init(code: String, name: String, attempts: Int, category: String, phone: String, locale: String, approved: Bool, version: Int, specialty: String, status: PrimaryAccessionClaimStatus) {
            self.code = code
            self.name = name
            self.attempts = attempts
            self.category = category
            self.phone = phone
            self.locale = locale
            self.approved = approved
            self.version = version
            self.specialty = specialty
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

        func canMoveTo(_ next: PrimaryAccessionClaimStatus) -> Bool {
            switch status {
            case .new:
                return next == PrimaryAccessionClaimStatus.queued || next == PrimaryAccessionClaimStatus.running
            case .queued:
                return next == PrimaryAccessionClaimStatus.failed
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == PrimaryAccessionClaimStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryAccessionClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary accession claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func projectedVolume() -> Double {
            return ((Double(attempts) - Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryAccessionClaim {
            return PrimaryAccessionClaim(
                code: code,
                name: name,
                attempts: attempts,
                category: category,
                phone: phone,
                locale: locale,
                approved: approved,
                version: version,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a primary accession claim in status new.
    static func newPrimaryAccessionClaim(_ code: String, name: String) -> PrimaryAccessionClaim {
        return PrimaryAccessionClaim(
            code: code,
            name: name,
            attempts: 0,
            category: "",
            phone: "",
            locale: "",
            approved: false,
            version: 0,
            specialty: "",
            status: PrimaryAccessionClaimStatus.new
        )
    }
}
