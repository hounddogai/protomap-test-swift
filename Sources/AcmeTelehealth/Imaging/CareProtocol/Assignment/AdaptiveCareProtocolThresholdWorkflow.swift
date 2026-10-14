import AcmePlatform
import Foundation

extension Imaging {
    /// Moves adaptive care protocol thresholds through their life cycle and keeps a journal of what it did.
    final class AdaptiveCareProtocolThresholdManager {
        var store: any AdaptiveCareProtocolThresholdStore
        var validator: AdaptiveCareProtocolThresholdValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any AdaptiveCareProtocolThresholdStore, validator: AdaptiveCareProtocolThresholdValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive care protocol threshold \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptiveCareProtocolThresholdStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive care protocol threshold \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptiveCareProtocolThresholdStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
                    continue
                }
                let problems = validator.validate(item)
                if problems.count == 0 {
                    continue
                }
                self.note("\(item.code) needs attention: \(problems.joined(separator: ", "))")
                changed += 1
            }
            return changed
        }
    }

    static func newAdaptiveCareProtocolThresholdManager(_ store: any AdaptiveCareProtocolThresholdStore, clock: any Kit.Clocks.Clock) -> AdaptiveCareProtocolThresholdManager {
        return AdaptiveCareProtocolThresholdManager(
            store: store,
            validator: defaultAdaptiveCareProtocolThresholdValidator(),
            clock: clock,
            journal: []
        )
    }
}
