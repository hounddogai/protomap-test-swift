import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves lenient outreach thresholds through their life cycle and keeps a journal of what it did.
    final class LenientOutreachThresholdManager {
        var store: any LenientOutreachThresholdStore
        var validator: LenientOutreachThresholdValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any LenientOutreachThresholdStore, validator: LenientOutreachThresholdValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("lenient outreach threshold \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientOutreachThresholdStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient outreach threshold \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientOutreachThresholdStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
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

    static func newLenientOutreachThresholdManager(_ store: any LenientOutreachThresholdStore, clock: any Kit.Clocks.Clock) -> LenientOutreachThresholdManager {
        return LenientOutreachThresholdManager(
            store: store,
            validator: defaultLenientOutreachThresholdValidator(),
            clock: clock,
            journal: []
        )
    }
}
