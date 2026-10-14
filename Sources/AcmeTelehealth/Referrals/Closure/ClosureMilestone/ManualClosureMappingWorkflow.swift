import AcmePlatform
import Foundation

extension Referrals {
    /// Moves manual closure mappings through their life cycle and keeps a journal of what it did.
    final class ManualClosureMappingService {
        var store: any ManualClosureMappingStore
        var validator: ManualClosureMappingValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ManualClosureMappingStore, validator: ManualClosureMappingValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual closure mapping \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualClosureMappingStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual closure mapping \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualClosureMappingStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newManualClosureMappingService(_ store: any ManualClosureMappingStore, clock: any Kit.Clocks.Clock) -> ManualClosureMappingService {
        return ManualClosureMappingService(
            store: store,
            validator: defaultManualClosureMappingValidator(),
            clock: clock,
            journal: []
        )
    }
}
