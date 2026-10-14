import AcmePlatform
import Foundation

extension Consent {
    /// Where a adaptive disclosure exception is in its life cycle.
    enum AdaptiveDisclosureExceptionStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A adaptive disclosure exception. Its code is unique within a tenant.
    final class AdaptiveDisclosureException {
        var code: String
        var name: String
        var specialty: String
        var startsAt: Int
        var payer: String
        var checksum: String
        var locale: String
        var version: Int
        var batchSize: Int
        var threshold: Double
        var reviewer: String
        var status: AdaptiveDisclosureExceptionStatus

        init(code: String, name: String, specialty: String, startsAt: Int, payer: String, checksum: String, locale: String, version: Int, batchSize: Int, threshold: Double, reviewer: String, status: AdaptiveDisclosureExceptionStatus) {
            self.code = code
            self.name = name
            self.specialty = specialty
            self.startsAt = startsAt
            self.payer = payer
            self.checksum = checksum
            self.locale = locale
            self.version = version
            self.batchSize = batchSize
            self.threshold = threshold
            self.reviewer = reviewer
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveDisclosureExceptionStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == AdaptiveDisclosureExceptionStatus.draining || next == AdaptiveDisclosureExceptionStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: AdaptiveDisclosureExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive disclosure exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedTotal() -> Double {
            return (Double(version) * threshold * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveDisclosureException {
            return AdaptiveDisclosureException(
                code: code,
                name: name,
                specialty: specialty,
                startsAt: startsAt,
                payer: payer,
                checksum: checksum,
                locale: locale,
                version: version,
                batchSize: batchSize,
                threshold: threshold,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a adaptive disclosure exception in status idle.
    static func newAdaptiveDisclosureException(_ code: String, name: String) -> AdaptiveDisclosureException {
        return AdaptiveDisclosureException(
            code: code,
            name: name,
            specialty: "",
            startsAt: 0,
            payer: "",
            checksum: "",
            locale: "",
            version: 0,
            batchSize: 0,
            threshold: 0.0,
            reviewer: "",
            status: AdaptiveDisclosureExceptionStatus.idle
        )
    }
}
