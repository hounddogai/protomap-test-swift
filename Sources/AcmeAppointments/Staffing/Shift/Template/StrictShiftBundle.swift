import AcmePlatform
import Foundation

extension Staffing {
    /// Where a strict shift bundle is in its life cycle.
    enum StrictShiftBundleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A strict shift bundle. Its code is unique within a tenant.
    final class StrictShiftBundle {
        var code: String
        var name: String
        var ward: String
        var threshold: Double
        var locale: String
        var ceiling: Double
        var channel: String
        var expiresAt: Int
        var score: Double
        var attributes: [String: String]
        var status: StrictShiftBundleStatus

        init(code: String, name: String, ward: String, threshold: Double, locale: String, ceiling: Double, channel: String, expiresAt: Int, score: Double, attributes: [String: String], status: StrictShiftBundleStatus) {
            self.code = code
            self.name = name
            self.ward = ward
            self.threshold = threshold
            self.locale = locale
            self.ceiling = ceiling
            self.channel = channel
            self.expiresAt = expiresAt
            self.score = score
            self.attributes = attributes
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

        func canMoveTo(_ next: StrictShiftBundleStatus) -> Bool {
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
                return next == StrictShiftBundleStatus.done
            case .running:
                return next == StrictShiftBundleStatus.done || next == StrictShiftBundleStatus.failed
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

        func moveTo(_ next: StrictShiftBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict shift bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("strict shift bundle") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func netVolume() -> Double {
            return ((threshold - score) * 100).rounded() / 100
        }

        func copyValue() -> StrictShiftBundle {
            return StrictShiftBundle(
                code: code,
                name: name,
                ward: ward,
                threshold: threshold,
                locale: locale,
                ceiling: ceiling,
                channel: channel,
                expiresAt: expiresAt,
                score: score,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a strict shift bundle in status new.
    static func newStrictShiftBundle(_ code: String, name: String) -> StrictShiftBundle {
        return StrictShiftBundle(
            code: code,
            name: name,
            ward: "",
            threshold: 0.0,
            locale: "",
            ceiling: 0.0,
            channel: "",
            expiresAt: 0,
            score: 0.0,
            attributes: [:],
            status: StrictShiftBundleStatus.new
        )
    }
}
