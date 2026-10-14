import AcmePlatform
import Foundation

extension Consent {
    /// Where a fallback proxy threshold is in its life cycle.
    enum FallbackProxyThresholdStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a fallback proxy threshold and its current status.
    final class FallbackProxyThreshold {
        var code: String
        var name: String
        var limit: Int
        var windowDays: Int
        var facility: String
        var checksum: String
        var attributes: [String: String]
        var contactEmail: String
        var status: FallbackProxyThresholdStatus

        init(code: String, name: String, limit: Int, windowDays: Int, facility: String, checksum: String, attributes: [String: String], contactEmail: String, status: FallbackProxyThresholdStatus) {
            self.code = code
            self.name = name
            self.limit = limit
            self.windowDays = windowDays
            self.facility = facility
            self.checksum = checksum
            self.attributes = attributes
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: FallbackProxyThresholdStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == FallbackProxyThresholdStatus.done || next == FallbackProxyThresholdStatus.failed
            case .done:
                return next == FallbackProxyThresholdStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackProxyThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback proxy threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
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

        func adjustedLoad() -> Double {
            return ((Double(limit) + Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackProxyThreshold {
            return FallbackProxyThreshold(
                code: code,
                name: name,
                limit: limit,
                windowDays: windowDays,
                facility: facility,
                checksum: checksum,
                attributes: attributes,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a fallback proxy threshold in status new.
    static func newFallbackProxyThreshold(_ code: String, name: String) -> FallbackProxyThreshold {
        return FallbackProxyThreshold(
            code: code,
            name: name,
            limit: 0,
            windowDays: 0,
            facility: "",
            checksum: "",
            attributes: [:],
            contactEmail: "",
            status: FallbackProxyThresholdStatus.new
        )
    }
}
