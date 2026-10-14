import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a manual denial tier is in its life cycle.
    enum ManualDenialTierStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A manual denial tier. Its code is unique within a tenant.
    final class ManualDenialTier {
        var code: String
        var label: String
        var reviewer: String
        var retries: Int
        var windowDays: Int
        var ceiling: Double
        var title: String
        var description: String
        var clinicianID: String
        var procedureCode: String
        var tags: [String]
        var status: ManualDenialTierStatus

        init(code: String, label: String, reviewer: String, retries: Int, windowDays: Int, ceiling: Double, title: String, description: String, clinicianID: String, procedureCode: String, tags: [String], status: ManualDenialTierStatus) {
            self.code = code
            self.label = label
            self.reviewer = reviewer
            self.retries = retries
            self.windowDays = windowDays
            self.ceiling = ceiling
            self.title = title
            self.description = description
            self.clinicianID = clinicianID
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: ManualDenialTierStatus) -> Bool {
            switch status {
            case .new:
                return next == ManualDenialTierStatus.running || next == ManualDenialTierStatus.failed
            case .queued:
                switch next {
                case .done, .failed:
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

        func moveTo(_ next: ManualDenialTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual denial tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("manual denial tier") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveExposure() -> Double {
            return ((ceiling - Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> ManualDenialTier {
            return ManualDenialTier(
                code: code,
                label: label,
                reviewer: reviewer,
                retries: retries,
                windowDays: windowDays,
                ceiling: ceiling,
                title: title,
                description: description,
                clinicianID: clinicianID,
                procedureCode: procedureCode,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a manual denial tier in status new.
    static func newManualDenialTier(_ code: String, label: String) -> ManualDenialTier {
        return ManualDenialTier(
            code: code,
            label: label,
            reviewer: "",
            retries: 0,
            windowDays: 0,
            ceiling: 0.0,
            title: "",
            description: "",
            clinicianID: "",
            procedureCode: "",
            tags: [],
            status: ManualDenialTierStatus.new
        )
    }
}
