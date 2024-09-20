#include "tiny_queue.hh"

// Create a queue, return a pointer to tiny_queue_t or NULL on error
tiny_queue_t *tiny_queue_create()
{
  struct tiny_queue_t *queue = (struct tiny_queue_t *)malloc(sizeof(struct tiny_queue_t));

  if (queue == nullptr)
  {
    return nullptr;
  }

  queue->head = nullptr;
  queue->tail = nullptr;

  if (pthread_mutex_init(&queue->mutex, nullptr) == 0 &&
      pthread_cond_init(&queue->wakeup, nullptr) == 0)
  {
    return queue;
  }

  free(queue);
  return nullptr;
}

// Push a pointer onto the queue, return -1 on error
int tiny_queue_push(tiny_queue_t *queue, tiny_queue_message_t *x)
{
  struct tiny_linked_list_t *new_node = (struct tiny_linked_list_t *)malloc(sizeof(struct tiny_linked_list_t));

  if (new_node == nullptr)
  {
    return -1;
  }

  new_node->data = x;
  new_node->next = nullptr;

  pthread_mutex_lock(&queue->mutex);
  if (queue->head == nullptr && queue->tail == nullptr)
  {
    queue->head = queue->tail = new_node;
  }
  else
  {
    queue->tail->next = new_node;
    queue->tail = new_node;
  }
  pthread_mutex_unlock(&queue->mutex);
  pthread_cond_signal(&queue->wakeup);

  return 0;
}

// Pop a pointer from the queue
void *tiny_queue_pop(tiny_queue_t *queue)
{
  pthread_mutex_lock(&queue->mutex);
  while (queue->head == nullptr)
  { // block if buffer is empty
    pthread_cond_wait(&queue->wakeup, &queue->mutex);
  }

  struct tiny_linked_list_t *current_head = queue->head;
  void *data = current_head->data;
  if (queue->head == queue->tail)
  {
    queue->head = queue->tail = nullptr;
  }
  else
  {
    queue->head = queue->head->next;
  }
  free(current_head);
  pthread_mutex_unlock(&queue->mutex);

  return data;
}

// Destroy the queue with all elements
int tiny_queue_destroy(tiny_queue_t *queue)
{
  if (pthread_mutex_destroy(&queue->mutex) != 0 ||
      pthread_cond_destroy(&queue->wakeup) != 0)
    return -1;

  struct tiny_linked_list_t *node, *next;
  node = queue->head;

  if (node != nullptr)
  {
    while (node->next != nullptr)
    {
      next = node->next;
      free(node);
      node = next;
    }
  }

  free(queue);

  return 0;
}
