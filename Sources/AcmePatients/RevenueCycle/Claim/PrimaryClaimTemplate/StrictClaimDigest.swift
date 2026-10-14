import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a strict claim digest is in its life cycle.
    enum StrictClaimDigestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A strict claim digest as the claim team keeps it.
    final class StrictClaimDigest {
        var code: String
        var name: String
        var createdAt: Int
        var acuity: Int
        var segment: String
        var budget: Double
        var allergy: String
        var patientRef: String
        var checksum: String
        var tags: [String]
        var status: StrictClaimDigestStatus

        init(code: String, name: String, createdAt: Int, acuity: Int, segment: String, budget: Double, allergy: String, patientRef: String, checksum: String, tags: [String], status: StrictClaimDigestStatus) {
            self.code = code
            self.name = name
            self.createdAt = createdAt
            self.acuity = acuity
            self.segment = segment
            self.budget = budget
            self.allergy = allergy
            self.patientRef = patientRef
            self.checksum = checksum
            self.tags = tags
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

        func canMoveTo(_ next: StrictClaimDigestStatus) -> Bool {
            switch status {
            case .new:
                return next == StrictClaimDigestStatus.running || next == StrictClaimDigestStatus.failed
            case .queued:
                return next == StrictClaimDigestStatus.done || next == StrictClaimDigestStatus.failed
            case .running:
                return next == StrictClaimDigestStatus.done
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

        func moveTo(_ next: StrictClaimDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict claim digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("strict claim digest") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveLoad() -> Double {
            return ((Double(createdAt) - Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> StrictClaimDigest {
            return StrictClaimDigest(
                code: code,
                name: name,
                createdAt: createdAt,
                acuity: acuity,
                segment: segment,
                budget: budget,
                allergy: allergy,
                patientRef: patientRef,
                checksum: checksum,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a strict claim digest in status new.
    static func newStrictClaimDigest(_ code: String, name: String) -> StrictClaimDigest {
        return StrictClaimDigest(
            code: code,
            name: name,
            createdAt: 0,
            acuity: 0,
            segment: "",
            budget: 0.0,
            allergy: "",
            patientRef: "",
            checksum: "",
            tags: [],
            status: StrictClaimDigestStatus.new
        )
    }
}
