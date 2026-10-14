import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a statement claim is in its life cycle.
    enum StatementClaimStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A statement claim. Its code is unique within a tenant.
    final class StatementClaim {
        var code: String
        var title: String
        var externalRef: String
        var rate: Double
        var refills: Int
        var discount: Double
        var retries: Int
        var contactEmail: String
        var checksum: String
        var payer: String
        var status: StatementClaimStatus

        init(code: String, title: String, externalRef: String, rate: Double, refills: Int, discount: Double, retries: Int, contactEmail: String, checksum: String, payer: String, status: StatementClaimStatus) {
            self.code = code
            self.title = title
            self.externalRef = externalRef
            self.rate = rate
            self.refills = refills
            self.discount = discount
            self.retries = retries
            self.contactEmail = contactEmail
            self.checksum = checksum
            self.payer = payer
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

        func canMoveTo(_ next: StatementClaimStatus) -> Bool {
            switch status {
            case .new:
                return next == StatementClaimStatus.failed
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == StatementClaimStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StatementClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("statement claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("statement claim") \(code)"
        }

        func adjustedVolume() -> Double {
            return (Double(refills) * Double(retries) * 100).rounded() / 100
        }

        func copyValue() -> StatementClaim {
            return StatementClaim(
                code: code,
                title: title,
                externalRef: externalRef,
                rate: rate,
                refills: refills,
                discount: discount,
                retries: retries,
                contactEmail: contactEmail,
                checksum: checksum,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a statement claim in status new.
    static func newStatementClaim(_ code: String, title: String) -> StatementClaim {
        return StatementClaim(
            code: code,
            title: title,
            externalRef: "",
            rate: 0.0,
            refills: 0,
            discount: 0.0,
            retries: 0,
            contactEmail: "",
            checksum: "",
            payer: "",
            status: StatementClaimStatus.new
        )
    }
}
