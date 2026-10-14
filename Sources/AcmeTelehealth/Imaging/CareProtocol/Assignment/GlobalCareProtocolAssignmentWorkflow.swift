import AcmePlatform
import Foundation

extension Imaging {
    /// Moves global care protocol assignments through their life cycle and keeps a journal of what it did.
    final class GlobalCareProtocolAssignmentDesk {
        var store: any GlobalCareProtocolAssignmentStore
        var validator: GlobalCareProtocolAssignmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any GlobalCareProtocolAssignmentStore, validator: GlobalCareProtocolAssignmentValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("global care protocol assignment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalCareProtocolAssignmentStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global care protocol assignment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalCareProtocolAssignmentStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newGlobalCareProtocolAssignmentDesk(_ store: any GlobalCareProtocolAssignmentStore, clock: any Kit.Clocks.Clock) -> GlobalCareProtocolAssignmentDesk {
        return GlobalCareProtocolAssignmentDesk(
            store: store,
            validator: defaultGlobalCareProtocolAssignmentValidator(),
            clock: clock,
            journal: []
        )
    }
}
