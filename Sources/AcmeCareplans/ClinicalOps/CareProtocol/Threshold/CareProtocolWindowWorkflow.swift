import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves care protocol windows through their life cycle and keeps a journal of what it did.
    final class CareProtocolWindowManager {
        var store: any CareProtocolWindowStore
        var validator: CareProtocolWindowValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CareProtocolWindowStore, validator: CareProtocolWindowValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("care protocol window \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CareProtocolWindowStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care protocol window \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CareProtocolWindowStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
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

    static func newCareProtocolWindowManager(_ store: any CareProtocolWindowStore, clock: any Kit.Clocks.Clock) -> CareProtocolWindowManager {
        return CareProtocolWindowManager(
            store: store,
            validator: defaultCareProtocolWindowValidator(),
            clock: clock,
            journal: []
        )
    }
}
