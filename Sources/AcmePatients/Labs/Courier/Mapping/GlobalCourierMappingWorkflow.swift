import AcmePlatform
import Foundation

extension Labs {
    /// Moves global courier mappings through their life cycle and keeps a journal of what it did.
    final class GlobalCourierMappingWorkflow {
        var store: any GlobalCourierMappingStore
        var validator: GlobalCourierMappingValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any GlobalCourierMappingStore, validator: GlobalCourierMappingValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("global courier mapping \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalCourierMappingStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global courier mapping \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalCourierMappingStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
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

    static func newGlobalCourierMappingWorkflow(_ store: any GlobalCourierMappingStore, clock: any Kit.Clocks.Clock) -> GlobalCourierMappingWorkflow {
        return GlobalCourierMappingWorkflow(
            store: store,
            validator: defaultGlobalCourierMappingValidator(),
            clock: clock,
            journal: []
        )
    }
}
