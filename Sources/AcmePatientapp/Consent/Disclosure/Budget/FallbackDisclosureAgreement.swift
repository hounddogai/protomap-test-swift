import AcmePlatform
import Foundation

extension Consent {
    /// Where a fallback disclosure agreement is in its life cycle.
    enum FallbackDisclosureAgreementStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A fallback disclosure agreement. Its code is unique within a tenant.
    final class FallbackDisclosureAgreement {
        var code: String
        var title: String
        var archived: Bool
        var category: String
        var refills: Int
        var externalRef: String
        var windowDays: Int
        var phone: String
        var score: Double
        var batchSize: Int
        var status: FallbackDisclosureAgreementStatus

        init(code: String, title: String, archived: Bool, category: String, refills: Int, externalRef: String, windowDays: Int, phone: String, score: Double, batchSize: Int, status: FallbackDisclosureAgreementStatus) {
            self.code = code
            self.title = title
            self.archived = archived
            self.category = category
            self.refills = refills
            self.externalRef = externalRef
            self.windowDays = windowDays
            self.phone = phone
            self.score = score
            self.batchSize = batchSize
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

        func canMoveTo(_ next: FallbackDisclosureAgreementStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == FallbackDisclosureAgreementStatus.done
            case .running:
                return next == FallbackDisclosureAgreementStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: FallbackDisclosureAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback disclosure agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("fallback disclosure agreement") \(code)"
        }

        func effectiveExposure() -> Double {
            return ((Double(refills) - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackDisclosureAgreement {
            return FallbackDisclosureAgreement(
                code: code,
                title: title,
                archived: archived,
                category: category,
                refills: refills,
                externalRef: externalRef,
                windowDays: windowDays,
                phone: phone,
                score: score,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a fallback disclosure agreement in status new.
    static func newFallbackDisclosureAgreement(_ code: String, title: String) -> FallbackDisclosureAgreement {
        return FallbackDisclosureAgreement(
            code: code,
            title: title,
            archived: false,
            category: "",
            refills: 0,
            externalRef: "",
            windowDays: 0,
            phone: "",
            score: 0.0,
            batchSize: 0,
            status: FallbackDisclosureAgreementStatus.new
        )
    }
}
