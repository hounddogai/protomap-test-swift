import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a legacy dispense batch is in its life cycle.
    enum LegacyDispenseBatchStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A legacy dispense batch as the dispense team keeps it.
    final class LegacyDispenseBatch {
        var code: String
        var title: String
        var tags: [String]
        var windowDays: Int
        var cost: Double
        var retries: Int
        var maximum: Double
        var category: String
        var facility: String
        var revision: Int
        var locale: String
        var status: LegacyDispenseBatchStatus

        init(code: String, title: String, tags: [String], windowDays: Int, cost: Double, retries: Int, maximum: Double, category: String, facility: String, revision: Int, locale: String, status: LegacyDispenseBatchStatus) {
            self.code = code
            self.title = title
            self.tags = tags
            self.windowDays = windowDays
            self.cost = cost
            self.retries = retries
            self.maximum = maximum
            self.category = category
            self.facility = facility
            self.revision = revision
            self.locale = locale
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

        func canMoveTo(_ next: LegacyDispenseBatchStatus) -> Bool {
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
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == LegacyDispenseBatchStatus.done
            case .done:
                return next == LegacyDispenseBatchStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyDispenseBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy dispense batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedValue() -> Double {
            return ((cost - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyDispenseBatch {
            return LegacyDispenseBatch(
                code: code,
                title: title,
                tags: tags,
                windowDays: windowDays,
                cost: cost,
                retries: retries,
                maximum: maximum,
                category: category,
                facility: facility,
                revision: revision,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a legacy dispense batch in status new.
    static func newLegacyDispenseBatch(_ code: String, title: String) -> LegacyDispenseBatch {
        return LegacyDispenseBatch(
            code: code,
            title: title,
            tags: [],
            windowDays: 0,
            cost: 0.0,
            retries: 0,
            maximum: 0.0,
            category: "",
            facility: "",
            revision: 0,
            locale: "",
            status: LegacyDispenseBatchStatus.new
        )
    }
}
